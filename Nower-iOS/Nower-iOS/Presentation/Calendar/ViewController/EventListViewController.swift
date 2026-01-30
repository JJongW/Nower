//
//  EventListViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//
import UIKit

final class EventListViewController: UIViewController {

    private let eventListView = EventListView()
    var coordinator: AppCoordinator?
    var selectedDate: Date!
    var viewModel: CalendarViewModel!

    override func loadView() {
        self.view = eventListView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        eventListView.eventTableView.dataSource = self
        eventListView.eventTableView.delegate = self
        eventListView.addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)

        reload()
    }

    private func reload() {
        viewModel.selectedDate = selectedDate
        viewModel.loadAllTodos()
        eventListView.eventTableView.reloadData()
        eventListView.eventDateLabel.text = selectedDate.formatted("dd")
        eventListView.eventWeekLabel.text = selectedDate.formattedUS("EEE.").uppercased()

        // 날짜에 따른 라벨 표시
        eventListView.eventLabel.text = getDateDescription(for: selectedDate)
    }

    private func getDateDescription(for date: Date) -> String {
        let calendar = Calendar.current
        let today = Date()

        if calendar.isDateInToday(date) {
            return "오늘"
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else if calendar.isDateInTomorrow(date) {
            return "내일"
        } else {
            // 같은 연도면 월만, 다른 연도면 연도.월 표시
            let dateYear = calendar.component(.year, from: date)
            let todayYear = calendar.component(.year, from: today)

            if dateYear == todayYear {
                return date.formatted("M월")
            } else {
                return date.formatted("yyyy.M월")
            }
        }
    }

    @objc private func didTapAdd() {
        let newVC = NewEventViewController()
        newVC.selectedDate = selectedDate
        newVC.viewModel = viewModel
        newVC.coordinator = coordinator
        if let sheet = newVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(newVC, animated: true)
    }
}

extension EventListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let todos = viewModel.todos(for: selectedDate)
        return todos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as? EventTableViewCell else {
            return UITableViewCell()
        }
        let todos = viewModel.todos(for: selectedDate)
        cell.configure(with: todos[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todo = viewModel.todos(for: selectedDate)[indexPath.row]
        let editVC = EditEventBottomSheetViewController()
        editVC.todo = todo
        editVC.viewModel = viewModel
        editVC.selectedDate = selectedDate
        editVC.coordinator = self.coordinator

        if let sheet = editVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(editVC, animated: true)
    }
}
