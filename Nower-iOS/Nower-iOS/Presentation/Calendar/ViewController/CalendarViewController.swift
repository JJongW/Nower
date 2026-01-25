//
//  CalendarViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.

import UIKit

final class CalendarViewController: UIViewController {

    var coordinator: AppCoordinator?
    private let calendarView = CalendarView()
    private var currentDate = Date()
    private var weeks: [[WeekDayInfo]] = [] // 주 단위로 그룹화된 날짜들

    private var selectedIndexPath: IndexPath?
    private var isNextMonth = false

    private let viewModel: CalendarViewModel
    private let holidayUseCase: HolidayUseCase

    // MARK: - Interactive Swipe Properties
    private var panStartLocation: CGPoint = .zero
    private var snapshotView: UIView?
    private var nextMonthSnapshot: UIView?
    private var isTransitioning = false
    private let swipeThreshold: CGFloat = 0.7 // 화면 너비의 70% 이상 스와이프해야 전환

    init(viewModel: CalendarViewModel, holidayUseCase: HolidayUseCase) {
        self.viewModel = viewModel
        self.holidayUseCase = holidayUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.debugPrintICloudTodos()
        // 날짜가 바뀌었을 수 있으므로 일일 명언 갱신
        calendarView.textLabel.text = DailyQuoteManager.getTodayQuote()
    }

    override func loadView() {
        self.view = calendarView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        generateCalendar()
        setupSwipeGesture()

        holidayUseCase.preloadAdjacentMonths(baseDate: currentDate, completion: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(icloudDidUpdate),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(forceSync),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        // CloudSyncManager의 알림을 수신하도록 변경
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(todosUpdated),
            name: Notification.Name("CloudSyncManager.todosDidUpdate"),
            object: nil
        )

        calendarView.previousButton.addTarget(self, action: #selector(didTapPreviousMonth), for: .touchUpInside)
        calendarView.nextButton.addTarget(self, action: #selector(didTapNextMonth), for: .touchUpInside)
    }

    private func setupCollectionView() {
        calendarView.collectionView.dataSource = self
        calendarView.collectionView.delegate = self
    }

    private func setupSwipeGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        calendarView.collectionView.addGestureRecognizer(panGesture)
    }

    // 이전/다음 달 스냅샷
    private var prevMonthSnapshot: UIView?

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let collectionView = calendarView.collectionView
        let containerWidth = collectionView.bounds.width
        let translation = gesture.translation(in: collectionView)

        switch gesture.state {
        case .began:
            panStartLocation = gesture.location(in: collectionView)
            isTransitioning = true

            // 컬렉션 뷰의 부모 뷰에서의 위치 계산
            let collectionViewFrame = collectionView.convert(collectionView.bounds, to: calendarView)

            // 현재 달력 스냅샷 생성
            snapshotView = collectionView.snapshotView(afterScreenUpdates: false)
            if let snapshot = snapshotView {
                snapshot.frame = collectionViewFrame
                snapshot.clipsToBounds = true // 클리핑 설정
                calendarView.addSubview(snapshot)
            }

            // 이전/다음 달 스냅샷 미리 생성
            createAdjacentMonthSnapshots(collectionView: collectionView, collectionViewFrame: collectionViewFrame)

            // 실제 collectionView 숨김
            collectionView.alpha = 0

        case .changed:
            guard let snapshot = snapshotView else { return }

            // 현재 달력 스냅샷 이동 (손가락 따라가기 - 약간의 저항감으로 더 자연스럽게)
            // 저항감: 이동 거리가 멀수록 약간 느려지도록 (0.95 배율)
            let resistance: CGFloat = 0.95
            let adjustedTranslation = translation.x * resistance
            snapshot.transform = CGAffineTransform(translationX: adjustedTranslation, y: 0)

            // 다음 달 스냅샷 위치 (오른쪽에서 들어옴)
            if let nextSnapshot = nextMonthSnapshot {
                nextSnapshot.transform = CGAffineTransform(translationX: containerWidth + adjustedTranslation, y: 0)
            }

            // 이전 달 스냅샷 위치 (왼쪽에서 들어옴)
            if let prevSnapshot = prevMonthSnapshot {
                prevSnapshot.transform = CGAffineTransform(translationX: -containerWidth + adjustedTranslation, y: 0)
            }

        case .ended, .cancelled:
            guard let snapshot = snapshotView else {
                isTransitioning = false
                return
            }

            let velocity = gesture.velocity(in: collectionView)
            let progress = abs(translation.x) / containerWidth

            // 스와이프 방향 결정 (속도 또는 거리 기반)
            let shouldComplete = progress > swipeThreshold || abs(velocity.x) > 500
            let isSwipingLeft = translation.x < 0 || (translation.x == 0 && velocity.x < 0)

            if shouldComplete {
                // 월 전환 완료
                if isSwipingLeft {
                    guard let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else {
                        cancelTransition(snapshot: snapshot, collectionView: collectionView)
                        return
                    }
                    completeInteractiveTransition(currentSnapshot: snapshot, collectionView: collectionView, newDate: newDate, direction: .left)
                } else {
                    guard let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else {
                        cancelTransition(snapshot: snapshot, collectionView: collectionView)
                        return
                    }
                    completeInteractiveTransition(currentSnapshot: snapshot, collectionView: collectionView, newDate: newDate, direction: .right)
                }
            } else {
                cancelTransition(snapshot: snapshot, collectionView: collectionView)
            }

        default:
            break
        }
    }

    /// 이전/다음 달 스냅샷을 미리 생성
    private func createAdjacentMonthSnapshots(collectionView: UICollectionView, collectionViewFrame: CGRect) {
        let containerWidth = collectionView.bounds.width
        let originalDate = currentDate
        let originalWeeks = weeks

        // 다음 달 스냅샷 생성
        if let nextDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = nextDate
            generateCalendarData()
            collectionView.reloadData()
            // 레이아웃 완전히 계산되도록 강제
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
            
            nextMonthSnapshot = collectionView.snapshotView(afterScreenUpdates: true)
            if let nextSnapshot = nextMonthSnapshot {
                nextSnapshot.frame = collectionViewFrame // 정확한 위치에 배치
                nextSnapshot.clipsToBounds = true // 클리핑 설정
                nextSnapshot.transform = CGAffineTransform(translationX: containerWidth, y: 0)
                calendarView.insertSubview(nextSnapshot, belowSubview: snapshotView ?? collectionView)
            }
        }

        // 이전 달 스냅샷 생성
        if let prevDate = Calendar.current.date(byAdding: .month, value: -1, to: originalDate) {
            currentDate = prevDate
            generateCalendarData()
            collectionView.reloadData()
            // 레이아웃 완전히 계산되도록 강제
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
            
            prevMonthSnapshot = collectionView.snapshotView(afterScreenUpdates: true)
            if let prevSnapshot = prevMonthSnapshot {
                prevSnapshot.frame = collectionViewFrame // 정확한 위치에 배치
                prevSnapshot.clipsToBounds = true // 클리핑 설정
                prevSnapshot.transform = CGAffineTransform(translationX: -containerWidth, y: 0)
                calendarView.insertSubview(prevSnapshot, belowSubview: snapshotView ?? collectionView)
            }
        }

        // 원래 데이터로 복원
        currentDate = originalDate
        weeks = originalWeeks
        collectionView.reloadData()
    }

    /// 인터랙티브 전환 완료
    private func completeInteractiveTransition(currentSnapshot: UIView, collectionView: UICollectionView, newDate: Date, direction: SlideDirection) {
        let containerWidth = collectionView.bounds.width
        let targetSnapshot = direction == .left ? nextMonthSnapshot : prevMonthSnapshot
        let otherSnapshot = direction == .left ? prevMonthSnapshot : nextMonthSnapshot

        // 새 달력 데이터로 업데이트
        currentDate = newDate
        generateCalendar()
        collectionView.alpha = 1
        collectionView.transform = .identity

        // 슬라이드 완료 애니메이션 (스프링 효과로 부드러운 밀어내기 느낌)
        let exitOffset: CGFloat = direction == .left ? -containerWidth : containerWidth
        let otherOffset: CGFloat = direction == .left ? -containerWidth * 2 : containerWidth * 2
        
        // 스프링 애니메이션으로 더 자연스러운 느낌
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.85, // 감쇠 비율 (높을수록 덜 튐)
            initialSpringVelocity: 0.3,   // 초기 속도
            options: [.curveEaseOut]
        ) {
            // 현재 달력은 반대 방향으로 밀려나감
            currentSnapshot.transform = CGAffineTransform(translationX: exitOffset, y: 0)

            // 대상 달력은 제자리로 (스프링 효과)
            targetSnapshot?.transform = .identity

            // 반대쪽 스냅샷은 더 멀리
            otherSnapshot?.transform = CGAffineTransform(translationX: otherOffset, y: 0)
        } completion: { _ in
            currentSnapshot.removeFromSuperview()
            self.snapshotView = nil
            self.nextMonthSnapshot?.removeFromSuperview()
            self.nextMonthSnapshot = nil
            self.prevMonthSnapshot?.removeFromSuperview()
            self.prevMonthSnapshot = nil
            self.isTransitioning = false
        }

        // 월 라벨도 함께 애니메이션 (더 부드럽게)
        UIView.transition(
            with: calendarView.monthLabel,
            duration: 0.5,
            options: [.transitionCrossDissolve]
        ) {
            self.updateMonthLabel()
        }
    }

    /// 달력 데이터만 생성 (UI reloadData 없이)
    private func generateCalendarData() {
        weeks = []

        var calendar = Calendar.current
        calendar.firstWeekday = 1

        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekdayIndex = (weekday + 6) % 7

        let numberOfDays = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        // 첫 주 생성 (빈 날짜 + 실제 날짜)
        var currentWeek: [WeekDayInfo] = []

        // 빈 날짜들 추가
        for _ in 0..<firstWeekdayIndex {
            currentWeek.append(createEmptyDayInfo())
        }

        // 첫 주의 실제 날짜들 추가
        let daysInFirstWeek = 7 - firstWeekdayIndex
        for day in 1...daysInFirstWeek {
            let dayInfo = createDayInfo(day: day, components: components, calendar: calendar)
            currentWeek.append(dayInfo)
        }
        weeks.append(currentWeek)

        // 나머지 주들 생성
        var currentDay = daysInFirstWeek + 1
        while currentDay <= numberOfDays {
            currentWeek = []
            let daysInThisWeek = min(7, numberOfDays - currentDay + 1)

            for day in currentDay..<(currentDay + daysInThisWeek) {
                let dayInfo = createDayInfo(day: day, components: components, calendar: calendar)
                currentWeek.append(dayInfo)
            }

            // 주가 7일이 안 되면 빈 날짜로 채움
            while currentWeek.count < 7 {
                currentWeek.append(createEmptyDayInfo())
            }

            weeks.append(currentWeek)
            currentDay += daysInThisWeek
        }
    }

    private func cancelTransition(snapshot: UIView, collectionView: UICollectionView) {
        let containerWidth = collectionView.bounds.width

        // 원위치로 복귀 애니메이션 (스프링 효과로 자연스럽게)
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,  // 감쇠 비율
            initialSpringVelocity: 0.5,   // 초기 속도
            options: [.curveEaseOut]
        ) {
            // 현재 달력 원위치로
            snapshot.transform = .identity
            // 다음 달 스냅샷은 오른쪽 밖으로
            self.nextMonthSnapshot?.transform = CGAffineTransform(translationX: containerWidth, y: 0)
            // 이전 달 스냅샷은 왼쪽 밖으로
            self.prevMonthSnapshot?.transform = CGAffineTransform(translationX: -containerWidth, y: 0)
        } completion: { _ in
            snapshot.removeFromSuperview()
            self.snapshotView = nil
            self.nextMonthSnapshot?.removeFromSuperview()
            self.nextMonthSnapshot = nil
            self.prevMonthSnapshot?.removeFromSuperview()
            self.prevMonthSnapshot = nil
            collectionView.alpha = 1
            self.isTransitioning = false
        }
    }

    @objc private func icloudDidUpdate(notification: Notification) {
        //viewModel.loadAllTodos()
        DispatchQueue.main.async {
            self.calendarView.collectionView.reloadData()
        }
    }

    @objc private func forceSync() {
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    private func preloadAdjacentMonths(baseDate: Date) {
        holidayUseCase.preloadAdjacentMonths(baseDate: baseDate, completion: {
            DispatchQueue.main.async {
                self.calendarView.collectionView.reloadData()
            }
        })
    }

    private func generateCalendar() {
        weeks = []

        var calendar = Calendar.current
        calendar.firstWeekday = 1

        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekdayIndex = (weekday + 6) % 7

        let numberOfDays = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        // 첫 주 생성 (빈 날짜 + 실제 날짜)
        var currentWeek: [WeekDayInfo] = []
        
        // 빈 날짜들 추가
        for _ in 0..<firstWeekdayIndex {
            currentWeek.append(createEmptyDayInfo())
        }

        // 첫 주의 실제 날짜들 추가
        let daysInFirstWeek = 7 - firstWeekdayIndex
        for day in 1...daysInFirstWeek {
            let dayInfo = createDayInfo(day: day, components: components, calendar: calendar)
            currentWeek.append(dayInfo)
        }
        weeks.append(currentWeek)

        // 나머지 주들 생성
        var currentDay = daysInFirstWeek + 1
        while currentDay <= numberOfDays {
            currentWeek = []
            let daysInThisWeek = min(7, numberOfDays - currentDay + 1)
            
            for day in currentDay..<(currentDay + daysInThisWeek) {
                let dayInfo = createDayInfo(day: day, components: components, calendar: calendar)
                currentWeek.append(dayInfo)
            }
            
            // 주가 7일이 안 되면 빈 날짜로 채움
            while currentWeek.count < 7 {
                currentWeek.append(createEmptyDayInfo())
            }
            
            weeks.append(currentWeek)
            currentDay += daysInThisWeek
        }

        updateMonthLabel()
        calendarView.collectionView.reloadData()

        if let year = components.year, let month = components.month {
            holidayUseCase.fetchHolidays(for: year, month: month) { _ in
                DispatchQueue.main.async {
                    self.calendarView.collectionView.reloadData()
                }
            }
        }
    }
    
    private func createDayInfo(day: Int, components: DateComponents, calendar: Calendar) -> WeekDayInfo {
        var dayComponents = components
        dayComponents.day = day
        guard let date = calendar.date(from: dayComponents) else {
            return createEmptyDayInfo()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let todos = viewModel.todos(for: date)
        let today = Date()
        let isToday = calendar.isDate(today, inSameDayAs: date)
        let holidayName = holidayUseCase.holidayName(for: date)
        let weekday = calendar.component(.weekday, from: date)
        let isSunday = weekday == 1
        let isSaturday = weekday == 7
        
        return WeekDayInfo(
            day: day,
            dateString: dateString,
            todos: todos,
            isToday: isToday,
            isSelected: false, // TODO: 선택 상태 관리 필요시 수정
            holidayName: holidayName,
            isSunday: isSunday,
            isSaturday: isSaturday
        )
    }
    
    private func createEmptyDayInfo() -> WeekDayInfo {
        return WeekDayInfo(
            day: nil,
            dateString: "",
            todos: [],
            isToday: false,
            isSelected: false,
            holidayName: nil,
            isSunday: false,
            isSaturday: false
        )
    }

    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy MMM"
        calendarView.monthLabel.text = formatter.string(from: currentDate)
    }

    @objc private func didTapPreviousMonth() {
        guard let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else { return }
        animateMonthTransition(to: newDate, direction: .right)
    }

    @objc private func didTapNextMonth() {
        guard let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else { return }
        animateMonthTransition(to: newDate, direction: .left)
    }

    private func animateMonthTransition(to newDate: Date, direction: SlideDirection) {
        let collectionView = calendarView.collectionView
        let containerWidth = collectionView.bounds.width

        // 컬렉션 뷰의 부모 뷰에서의 위치 계산
        let collectionViewFrame = collectionView.convert(collectionView.bounds, to: calendarView)

        // 스냅샷 생성 (현재 달력)
        guard let snapshot = collectionView.snapshotView(afterScreenUpdates: false) else {
            currentDate = newDate
            generateCalendar()
            return
        }

        snapshot.frame = collectionViewFrame // 정확한 위치에 배치
        snapshot.clipsToBounds = true // 클리핑 설정
        calendarView.addSubview(snapshot)

        // 새 달력 데이터로 업데이트
        currentDate = newDate
        generateCalendar()

        // 새 달력 초기 위치 설정 (화면 밖)
        let offsetX: CGFloat = direction == .left ? containerWidth : -containerWidth
        collectionView.transform = CGAffineTransform(translationX: offsetX, y: 0)

        // 슬라이드 애니메이션 (스프링 효과로 부드러운 밀어내기 느낌)
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.85, // 감쇠 비율 (높을수록 덜 튐)
            initialSpringVelocity: 0.3,   // 초기 속도
            options: [.curveEaseOut]
        ) {
            // 기존 달력 밀려나감
            snapshot.transform = CGAffineTransform(translationX: -offsetX, y: 0)
            // 새 달력 들어옴
            collectionView.transform = .identity
        } completion: { _ in
            snapshot.removeFromSuperview()
        }

        // 월 라벨도 함께 애니메이션 (더 부드럽게)
        UIView.transition(
            with: calendarView.monthLabel,
            duration: 0.5,
            options: [.transitionCrossDissolve]
        ) {
            self.updateMonthLabel()
        }
    }

    private enum SlideDirection {
        case left, right
    }

    /// Todo 데이터가 업데이트되었을 때 UI를 새로고침합니다.
    /// CloudSyncManager에서 발송하는 알림을 수신하여 처리합니다.
    @objc private func todosUpdated() {
        DispatchQueue.main.async {
            // ViewModel의 데이터를 새로 로드
            self.viewModel.loadAllTodos()
            // 달력 데이터 재생성 (주 단위로 그룹화)
            self.generateCalendar()
        }
    }
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weeks.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 주 단위 셀 선택은 WeekView의 touchesEnded에서 처리됨
        // 이 메서드는 빈 구현으로 두거나, 필요시 추가 처리 가능
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Separator 제거 - 셀 간격 없이 연결된 느낌을 위해
        if let separator = cell.contentView.viewWithTag(999) {
            separator.removeFromSuperview()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WeekCell.identifier, for: indexPath) as? WeekCell else {
            return UICollectionViewCell()
        }

        guard indexPath.item < weeks.count else { return cell }
        
        let week = weeks[indexPath.item]
        
        // 선택 상태 업데이트 (필요시)
        var updatedWeek = week
        // TODO: 선택된 날짜에 따라 isSelected 업데이트
        
        cell.configure(weekDays: updatedWeek)

        // 날짜 선택 콜백 설정
        cell.onDaySelected = { [weak self] dateString in
            self?.handleDaySelection(dateString: dateString)
        }

        // 일정 선택 콜백 설정 (기간별 일정 터치 시)
        cell.onTodoSelected = { [weak self] todo, dateString in
            self?.handleTodoSelection(todo: todo, dateString: dateString)
        }

        return cell
    }

    private func handleTodoSelection(todo: TodoItem, dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let selectedDate = formatter.date(from: dateString) else { return }

        coordinator?.presentEditEvent(todo: todo, date: selectedDate, viewModel: viewModel)
    }

    private func handleDaySelection(dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let selectedDate = formatter.date(from: dateString) else { return }

        let hasTodos = !viewModel.todos(for: selectedDate).isEmpty

        if hasTodos {
            coordinator?.presentEventList(for: selectedDate, viewModel: viewModel)
        } else {
            coordinator?.presentNewEvent(for: selectedDate, viewModel: viewModel)
        }
    }
}

extension CalendarViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 주 단위 셀: 전체 너비 사용, 높이는 실제 주 개수에 맞게 동적 계산
        let availableWidth = collectionView.bounds.width
        let availableHeight = collectionView.bounds.height

        // 실제 주 개수로 높이 계산 (4주~6주)
        let numberOfWeeks = weeks.count
        guard numberOfWeeks > 0 else {
            return CGSize(width: availableWidth, height: 80)
        }

        // 사용 가능한 높이를 주 개수로 균등 분배
        let cellHeight = availableHeight / CGFloat(numberOfWeeks)

        return CGSize(width: availableWidth, height: cellHeight)
    }
}
