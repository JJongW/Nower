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
    }

    @objc private func didTapAdd() {
        let newVC = NewEventViewController()
        newVC.selectedDate = selectedDate
        newVC.viewModel = viewModel
        newVC.coordinator = coordinator
        if let sheet = newVC.sheetPresentationController {
            sheet.detents = [.medium()]
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
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(editVC, animated: true)
    }
}
