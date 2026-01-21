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
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        calendarView.collectionView.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        calendarView.collectionView.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            didTapNextMonth()
        case .right:
            didTapPreviousMonth()
        default:
            break
        }
    }

    @objc private func icloudDidUpdate(notification: Notification) {
        print("📥 iCloud 변경 감지됨 - 일정 새로고침")
        //viewModel.loadAllTodos()
        DispatchQueue.main.async {
            self.calendarView.collectionView.reloadData()
        }
    }

    @objc private func forceSync() {
        NSUbiquitousKeyValueStore.default.synchronize()
        print("🔄 수동 iCloud 동기화 요청됨")
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
        currentDate = newDate
        isNextMonth = false
        generateCalendar()
        animateCalendarTransition(direction: .transitionFlipFromLeft)
    }

    @objc private func didTapNextMonth() {
        guard let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else { return }
        currentDate = newDate
        isNextMonth = true
        generateCalendar()
        animateCalendarTransition(direction: .transitionFlipFromLeft)
    }

    private func animateCalendarTransition(direction: UIView.AnimationOptions) {
        generateCalendar()

        UIView.transition(with: calendarView.collectionView,
                          duration: 0.3,
                          options: [direction, .transitionCrossDissolve],
                          animations: {
                              self.calendarView.collectionView.reloadData()
                          },
                          completion: nil)
    }

    /// Todo 데이터가 업데이트되었을 때 UI를 새로고침합니다.
    /// CloudSyncManager에서 발송하는 알림을 수신하여 처리합니다.
    @objc private func todosUpdated() {
        print("📱 [CalendarViewController] Todo 업데이트 알림 수신됨 - UI 새로고침 시작")
        DispatchQueue.main.async {
            // ViewModel의 데이터를 새로 로드
            self.viewModel.loadAllTodos()
            // 달력 데이터 재생성 (주 단위로 그룹화)
            self.generateCalendar()
            print("✅ [CalendarViewController] UI 새로고침 완료")
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

        return cell
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
        // 주 단위 셀: 전체 너비를 사용, 높이는 동적 계산
        let availableWidth = collectionView.bounds.width
        let cellWidth = availableWidth
        let cellHeight: CGFloat = 120 // 주 단위 셀 높이 (조정 가능)
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
