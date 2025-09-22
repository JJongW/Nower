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
    private var days: [String] = []

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
        days = []

        var calendar = Calendar.current
        calendar.firstWeekday = 1

        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekdayIndex = (weekday + 6) % 7

        let numberOfDays = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        for _ in 0..<firstWeekdayIndex {
            days.append("")
        }

        for day in 1...numberOfDays {
            days.append("\(day)")
        }

        updateMonthLabel()
        calendarView.collectionView.reloadData()
        
        // 기간별 일정 오버레이 업데이트 (CollectionView 렌더링 후 실행)
        DispatchQueue.main.async {
            self.updatePeriodEventOverlays()
        }

        if let year = components.year, let month = components.month {
            holidayUseCase.fetchHolidays(for: year, month: month) { _ in
                DispatchQueue.main.async {
                    self.calendarView.collectionView.reloadData()
                    // 공휴일 로드 후에도 오버레이 업데이트 (CollectionView 렌더링 후 실행)
                    DispatchQueue.main.async {
                        self.updatePeriodEventOverlays()
                    }
                }
            }
        }
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
            // CollectionView 전체를 새로고침하여 변경사항 반영
            self.calendarView.collectionView.reloadData()
            // 기간별 일정 오버레이 업데이트 (CollectionView 렌더링 후 실행)
            DispatchQueue.main.async {
                self.updatePeriodEventOverlays()
            }
            print("✅ [CalendarViewController] UI 새로고침 완료")
        }
    }
    
    // MARK: - 기간별 일정 오버레이 관리
    
    /// 기간별 일정 오버레이를 업데이트합니다.
    private func updatePeriodEventOverlays() {
        print("🔄 [CalendarViewController] 기간별 일정 오버레이 업데이트 시작")
        
        // 기존 오버레이 제거
        calendarView.clearPeriodEventOverlays()
        
        // 현재 월의 모든 기간별 일정 수집
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components),
              let numberOfDays = calendar.range(of: .day, in: .month, for: currentDate)?.count else { return }
        
        var periodTodos: [TodoItem] = []
        
        // 현재 월의 모든 날짜를 확인하여 기간별 일정 수집
        for day in 1...numberOfDays {
            var dayComponents = components
            dayComponents.day = day
            guard let date = calendar.date(from: dayComponents) else { continue }
            
            let todosForDate = viewModel.todos(for: date).filter { $0.isPeriodEvent }
            for todo in todosForDate {
                // 중복 제거: 같은 ID의 일정이 이미 있는지 확인
                if !periodTodos.contains(where: { $0.id == todo.id }) {
                    periodTodos.append(todo)
                    print("📅 [CalendarViewController] 기간별 일정 발견: \(todo.text), 시작: \(todo.startDate ?? "nil"), 종료: \(todo.endDate ?? "nil")")
                }
            }
        }
        
        print("📊 [CalendarViewController] 총 \(periodTodos.count)개의 기간별 일정 발견")
        
        // 기간별 일정들을 시작일 순으로 정렬
        let sortedPeriodTodos = periodTodos.sorted { first, second in
            guard let firstStart = first.startDateObject,
                  let secondStart = second.startDateObject else { return false }
            return firstStart < secondStart
        }
        
        // 각 기간별 일정에 대해 오버레이 생성 (기존 일정들을 고려한 row 계산)
        for (index, todo) in sortedPeriodTodos.enumerated() {
            print("🎨 [CalendarViewController] \(index)번째 일정 오버레이 생성: \(todo.text)")
            let optimalRow = calculateOptimalRowForPeriodEvent(todo, existingPeriodTodos: Array(sortedPeriodTodos.prefix(index)))
            createOverlayForPeriodTodo(todo, row: optimalRow)
        }
        
        print("✅ [CalendarViewController] 기간별 일정 오버레이 업데이트 완료")
    }
    
    /// 기간별 일정의 최적 행을 계산합니다 (공휴일 아래, 단일 날짜 일정 위)
    private func calculateOptimalRowForPeriodEvent(_ todo: TodoItem, existingPeriodTodos: [TodoItem]) -> Int {
        guard let startDate = todo.startDateObject,
              let endDate = todo.endDateObject else { return 0 }
        
        let calendar = Calendar.current
        var currentDate = startDate
        var maxRequiredRow = 0
        
        // 기간 내의 각 날짜에서 필요한 최소 행 계산
        while currentDate <= endDate {
            // 공휴일이 있는지 확인 (공휴일은 항상 최상위)
            let hasHoliday = holidayUseCase.holidayName(for: currentDate) != nil ? 1 : 0
            
            // 해당 날짜에 이미 표시되는 기간별 일정 수 계산
            let existingPeriodTodosForDate = existingPeriodTodos.filter { existingTodo in
                existingTodo.includesDate(currentDate)
            }.count
            
            // 기간별 일정 행 = 공휴일 다음 + 이미 배치된 기간별 일정들
            let requiredRow = hasHoliday + existingPeriodTodosForDate
            maxRequiredRow = max(maxRequiredRow, requiredRow)
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        print("📊 [CalendarViewController] \(todo.text) 최적 행 (공휴일 아래, 단일 일정 위): \(maxRequiredRow)")
        return maxRequiredRow
    }
    
    /// 특정 기간별 일정에 대한 오버레이를 생성합니다.
    private func createOverlayForPeriodTodo(_ todo: TodoItem, row: Int) {
        guard let startDate = todo.startDateObject,
              let endDate = todo.endDateObject else { 
            print("❌ [CalendarViewController] 날짜 파싱 실패: \(todo.text)")
            return 
        }
        
        print("📅 [CalendarViewController] 오버레이 생성 중: \(todo.text), \(startDate) ~ \(endDate)")
        
        // 시작일과 종료일이 현재 월에 포함되는 부분만 계산
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components),
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth) else { return }
        
        // 현재 월 범위 내에서 시작일과 종료일 조정
        let displayStartDate = max(startDate, firstDayOfMonth)
        let displayEndDate = min(endDate, lastDayOfMonth)
        
        print("📊 [CalendarViewController] 표시 범위: \(displayStartDate) ~ \(displayEndDate)")
        
        // 기간별 일정의 세그먼트들 생성
        let segments = createSegmentsForPeriodEvent(
            startDate: displayStartDate,
            endDate: displayEndDate,
            row: row
        )
        
        print("🔧 [CalendarViewController] 생성된 세그먼트 수: \(segments.count)")
        
        if !segments.isEmpty {
            calendarView.addPeriodEventOverlay(todo: todo, segments: segments, row: row)
            print("✅ [CalendarViewController] 오버레이 추가 완료: \(todo.text)")
        } else {
            print("⚠️ [CalendarViewController] 세그먼트가 생성되지 않음: \(todo.text)")
        }
    }
    
    /// 기간별 일정의 세그먼트들을 생성합니다.
    private func createSegmentsForPeriodEvent(startDate: Date, endDate: Date, row: Int) -> [PeriodEventSegment] {
        var segments: [PeriodEventSegment] = []
        let calendar = Calendar.current
        
        // 캘린더 레이아웃 정보 (DateCell 구조에 맞춤)
        let eventHeight: CGFloat = 18
        let eventSpacing: CGFloat = 1 // DateCell과 동일한 spacing
        // dayLabel(12px + 1px) + holidayLabel(10px + 1px) = 약 24px (공휴일 있을 때)
        // 공휴일 없을 때: dayLabel(12px + 1px) + holidayLabel(0px + 1px) = 약 14px
        let baseEventTopMargin: CGFloat = 24 
        let cellSpacing: CGFloat = 8
        
        // 시작일부터 종료일까지 날짜별로 처리
        var currentDate = startDate
        var isFirstSegment = true
        
        while currentDate <= endDate {
            guard let indexPath = indexPathForDate(currentDate),
                  let cell = calendarView.collectionView.cellForItem(at: indexPath) else {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                continue
            }
            
            let cellFrame = calendarView.collectionView.convert(cell.frame, to: calendarView.periodEventOverlayContainer)
            
            // 해당 날짜의 공휴일 여부에 따라 동적으로 topMargin 계산
            let hasHoliday = holidayUseCase.holidayName(for: currentDate) != nil
            let dynamicTopMargin = hasHoliday ? 24 : 15 // 공휴일 있으면 24, 없으면 15
            
            // 현재 행에서 이 날짜부터 행 끝까지 또는 종료일까지의 연속된 날짜들 찾기
            let rowSegment = createRowSegment(
                startDate: currentDate,
                endDate: endDate,
                currentCellFrame: cellFrame,
                row: row,
                eventHeight: eventHeight,
                eventSpacing: eventSpacing,
                eventTopMargin: CGFloat(dynamicTopMargin),
                isFirst: isFirstSegment
            )
            
            if let segment = rowSegment.segment {
                segments.append(segment)
                currentDate = rowSegment.nextDate
                isFirstSegment = false // 첫 번째 세그먼트 이후는 모두 false
                
                print("📅 [CalendarViewController] 세그먼트 생성 완료 - 첫번째: \(segment.isFirstSegment), 마지막: \(segment.isLastSegment)")
            } else {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return segments
    }
    
    /// 한 행에서의 세그먼트를 생성합니다.
    private func createRowSegment(
        startDate: Date,
        endDate: Date,
        currentCellFrame: CGRect,
        row: Int,
        eventHeight: CGFloat,
        eventSpacing: CGFloat,
        eventTopMargin: CGFloat,
        isFirst: Bool
    ) -> (segment: PeriodEventSegment?, nextDate: Date) {
        
        let calendar = Calendar.current
        var currentDate = startDate
        var segmentEndDate = startDate
        let currentRow = Int(currentCellFrame.minY / (currentCellFrame.height + 8)) // 대략적인 행 계산
        
        // 같은 행에 있는 연속된 날짜들을 찾기
        while segmentEndDate <= endDate {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: segmentEndDate) ?? segmentEndDate
            
            if nextDate > endDate {
                break
            }
            
            guard let nextIndexPath = indexPathForDate(nextDate),
                  let nextCell = calendarView.collectionView.cellForItem(at: nextIndexPath) else {
                break
            }
            
            let nextCellFrame = calendarView.collectionView.convert(nextCell.frame, to: calendarView.periodEventOverlayContainer)
            let nextRow = Int(nextCellFrame.minY / (nextCellFrame.height + 8))
            
            // 다음 날이 다른 행에 있으면 현재 행 세그먼트 종료
            if nextRow != currentRow {
                break
            }
            
            segmentEndDate = nextDate
        }
        
        // 세그먼트 종료일의 셀 프레임 가져오기
        guard let endIndexPath = indexPathForDate(segmentEndDate),
              let endCell = calendarView.collectionView.cellForItem(at: endIndexPath) else {
            return (nil, calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate)
        }
        
        let endCellFrame = calendarView.collectionView.convert(endCell.frame, to: calendarView.periodEventOverlayContainer)
        
        // 세그먼트 프레임 계산
        let segmentFrame = CGRect(
            x: currentCellFrame.minX,
            y: currentCellFrame.minY + eventTopMargin + CGFloat(row) * (eventHeight + eventSpacing),
            width: endCellFrame.maxX - currentCellFrame.minX,
            height: eventHeight
        )
        
        let segment = PeriodEventSegment(
            frame: segmentFrame,
            isFirstSegment: isFirst, // 전체 기간의 첫 번째 세그먼트인지
            isLastSegment: segmentEndDate == endDate // 전체 기간의 마지막 세그먼트인지
        )
        
        let nextDate = calendar.date(byAdding: .day, value: 1, to: segmentEndDate) ?? segmentEndDate
        return (segment, nextDate)
    }
    
    /// 특정 날짜에 해당하는 IndexPath를 찾습니다.
    private func indexPathForDate(_ date: Date) -> IndexPath? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return nil }
        
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekdayIndex = (weekday + 6) % 7
        
        let targetDay = calendar.component(.day, from: date)
        let targetComponents = calendar.dateComponents([.year, .month], from: date)
        
        // 같은 년월인지 확인
        if targetComponents.year == components.year && targetComponents.month == components.month {
            let index = firstWeekdayIndex + targetDay - 1
            return IndexPath(item: index, section: 0)
        }
        
        return nil
    }
}

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard days[indexPath.item] != "" else { return }

        let day = Int(days[indexPath.item]) ?? 1
        var dateComponents = Calendar.current.dateComponents([.year, .month], from: currentDate)
        dateComponents.day = day

        guard let selectedDate = Calendar.current.date(from: dateComponents) else { return }

        let hasTodos = !viewModel.todos(for: selectedDate).isEmpty

        if hasTodos {
            coordinator?.presentEventList(for: selectedDate, viewModel: viewModel)
        } else {
            coordinator?.presentNewEvent(for: selectedDate, viewModel: viewModel)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell.contentView.viewWithTag(999) == nil {
            let separator = UIView()
            separator.tag = 999
            separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            cell.contentView.addSubview(separator)

            separator.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview()
                $0.bottom.equalToSuperview()
                $0.height.equalTo(0.5)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateCell.identifier, for: indexPath) as? DateCell else {
            return UICollectionViewCell()
        }

        let dayText = days[indexPath.item]
        if let day = Int(dayText) {
            var dateComponents = Calendar.current.dateComponents([.year, .month], from: currentDate)
            dateComponents.day = day
            guard let date = Calendar.current.date(from: dateComponents) else { return cell }

            let todos = viewModel.todos(for: date)
            let calendar = Calendar.current
            let today = Date()
            let isToday = calendar.isDate(today, inSameDayAs: date)
            let dayString = date.formatted("yyyy-MM-dd")
            let isSelected = indexPath == selectedIndexPath
            let holidayName = holidayUseCase.holidayName(for: date)
            let weekday = Calendar.current.component(.weekday, from: date)
            let isSunday = weekday == 1
            let isSaturday = weekday == 7

            cell.configure(
                day: day,
                todos: todos,
                isToday: isToday,
                isSelected: isSelected,
                dateString: dayString,
                holidayName: holidayName,
                isSunday: isSunday,
                isSaturday: isSaturday
            )
        } else {
            cell.configureEmpty()
        }

        return cell
    }
}

extension CalendarViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 8 * 6
        let availableWidth = collectionView.bounds.width - totalSpacing
        let cellWidth = floor(availableWidth / 7)
        let cellHeight = cellWidth * 2.1
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
