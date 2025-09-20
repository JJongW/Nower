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
            name: CloudSyncManager.todosDidUpdateNotification,
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

        if let year = components.year, let month = components.month {
            holidayUseCase.fetchHolidays(for: year, month: month) { _ in
                DispatchQueue.main.async {
                    self.calendarView.collectionView.reloadData()
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
            print("✅ [CalendarViewController] UI 새로고침 완료")
        }
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
