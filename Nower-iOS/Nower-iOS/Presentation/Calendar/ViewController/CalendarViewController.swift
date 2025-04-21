//
//  CalendarViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.

import UIKit

class CalendarViewController: UIViewController {

    private let calendarView = CalendarView()
    private var currentDate = Date()
    private var days: [String] = []

    private var selectedIndexPath: IndexPath?
    private var isNextMonth = false

    override func loadView() {
        self.view = calendarView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        generateCalendar()
        setupSwipeGesture()

        CalendarDataManager.shared.preloadAdjacentMonths(baseDate: currentDate)

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
        NotificationCenter.default.addObserver(self, selector: #selector(todosUpdated), name: .init("TodosUpdated"), object: nil)

        calendarView.previousButton.addTarget(self, action: #selector(didTapPreviousMonth), for: .touchUpInside)
        calendarView.nextButton.addTarget(self, action: #selector(didTapNextMonth), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)
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
        EventManager.shared.loadTodos()
        DispatchQueue.main.async {
            self.calendarView.collectionView.reloadData()
        }
    }

    @objc private func forceSync() {
        NSUbiquitousKeyValueStore.default.synchronize()
        print("🔄 수동 iCloud 동기화 요청됨")
    }

    func preloadAdjacentMonths(baseDate: Date) {
        let calendar = Calendar.current
        let current = baseDate
        let prev = calendar.date(byAdding: .month, value: -1, to: current)!
        let next = calendar.date(byAdding: .month, value: 1, to: current)!

        for date in [prev, current, next] {
            let comps = calendar.dateComponents([.year, .month], from: date)
            CalendarDataManager.shared.fetchHolidays(for: comps.year!, month: comps.month!) {
                DispatchQueue.main.async {
                    print("📆 미리 달력 새로고침")
                    self.calendarView.collectionView.reloadData()
                }
            }
        }
    }


    // MARK: - 달력 생성
    private func generateCalendar() {
        days = []

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDays = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        for _ in 1..<weekday {
            days.append("")
        }

        for day in 1...numberOfDays {
            days.append("\(day)")
        }

        updateMonthLabel()
        calendarView.collectionView.reloadData()

        CalendarDataManager.shared.fetchHolidays(for: components.year ?? 2025, month: components.month ?? 1) {
            DispatchQueue.main.async {
                self.calendarView.collectionView.reloadData()
            }
        }
    }

    // MARK: - 월 표시
    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy MMM"
        calendarView.monthLabel.text = formatter.string(from: currentDate)
    }

    // MARK: - 월 이동

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

    @objc private func todosUpdated() {
        DispatchQueue.main.async {
            self.calendarView.collectionView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDataSource
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

        let hasTodos = !EventManager.shared.todos(on: selectedDate).isEmpty

        if hasTodos {
            let vc = EventListViewController()
            vc.selectedDate = selectedDate
            present(vc, animated: true)
        } else {
            let addVC = NewEventViewController()
            addVC.selectedDate = selectedDate
            addVC.onSave = { todo in
                EventManager.shared.addTodo(todo)
                collectionView.reloadData()
            }
            if let sheet = addVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
            addVC.modalPresentationStyle = .pageSheet
            present(addVC, animated: true)
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

            let todos = EventManager.shared.todos(on: date)
            let calendar = Calendar.current
            let today = Date()
            let isToday = calendar.isDate(today, inSameDayAs: date)
            let dayString = date.formatted("yyyy-MM-dd")
            let isSelected = indexPath == selectedIndexPath
            cell.configure(day: day, todos: todos, isToday: isToday, isSelected: isSelected, dateString: dayString)
        } else {
            cell.configureEmpty()
        }

        return cell
    }

}

// MARK: - UICollectionViewDelegateFlowLayout
extension CalendarViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 8 * 6
        let availableWidth = collectionView.bounds.width - totalSpacing
        let cellWidth = floor(availableWidth / 6.5)
        let cellHeight = cellWidth * 2.1
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
