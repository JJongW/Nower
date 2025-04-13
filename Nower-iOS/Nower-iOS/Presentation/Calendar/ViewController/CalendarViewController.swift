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

    // MARK: - 달력 생성
    private func generateCalendar() {
        days = []

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDays = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        // 앞에 빈 칸 채우기
        for _ in 1..<weekday {
            days.append("") // 빈 셀
        }

        // 날짜 채우기
        for day in 1...numberOfDays {
            days.append("\(day)")
        }

        updateMonthLabel()
        calendarView.collectionView.reloadData()
    }

    // MARK: - 월 표시
    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        calendarView.monthLabel.text = formatter.string(from: currentDate)
    }

    // MARK: - 월 이동
    @objc private func moveMonth(by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) else { return }
        currentDate = newDate
        generateCalendar()
    }

    @objc private func didTapPreviousMonth() {
        guard let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else { return }
        currentDate = newDate
        isNextMonth = false
        generateCalendar()
    }

    @objc private func didTapNextMonth() {
        guard let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else { return }
        currentDate = newDate
        isNextMonth = true
        generateCalendar()
    }
    @objc private func todosUpdated() {
        calendarView.collectionView.reloadData()
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

        let newEventVC = NewEventViewController()
        newEventVC.selectedDate = selectedDate
        newEventVC.onSave = { [weak self] newTodo in
            guard let self = self else { return }

            // 저장하는 로직
            EventManager.shared.addTodo(newTodo)

            // 달력 새로고침
            self.calendarView.collectionView.reloadData()
        }

        present(newEventVC, animated: true)
    }


    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        // 선이 이미 있는 경우 중복 추가 방지
        if cell.contentView.viewWithTag(999) == nil {
            let separator = UIView()
            separator.tag = 999
            separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3) // 연한 회색 선
            cell.contentView.addSubview(separator)

            separator.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(0.5) // 얇은 0.5pt
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
            let isSelected = indexPath == selectedIndexPath

            cell.configure(day: day, todos: todos, isToday: isToday, isSelected: isSelected)
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
