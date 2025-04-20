//
//  EventListViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//
import UIKit
import SnapKit

final class EventListViewController: UIViewController {

    var selectedDate: Date!
    private var todos: [TodoItem] = []

    private let eventDateLabel: UILabel = {
        let label = UILabel()
        label.text = "25.04.16"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let eventTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(hex: "#FFFFFF")
        return tableView
    }()

    private let addButton: UIButton = {
        let button = UIButton()
        button.setTitle("＋", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        button.backgroundColor = UIColor(hex: "#101010")
        button.tintColor = .white
        button.layer.cornerRadius = 25
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTodos()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        eventTableView.dataSource = self
        eventTableView.delegate = self
        eventTableView.register(EventTableViewCell.self, forCellReuseIdentifier: "EventCell")

        view.addSubview(eventDateLabel)
        eventDateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.leading.equalToSuperview().offset(20)
        }

        view.addSubview(eventTableView)
        eventTableView.snp.makeConstraints {
            $0.top.equalTo(eventDateLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(addButton)
        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(50)
        }
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
    }

    private func loadTodos() {
        todos = EventManager.shared.todos(on: selectedDate)
        eventDateLabel.text = selectedDate.formatted("yy.MM.dd")
        eventTableView.reloadData()
    }

    @objc private func didTapAdd() {
        let addVC = NewEventViewController()
        addVC.selectedDate = selectedDate
        if let sheet = addVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        addVC.modalPresentationStyle = .pageSheet
        addVC.onSave = { [weak self] todo in
            EventManager.shared.addTodo(todo)
            self?.loadTodos()
            self?.dismiss(animated: true)
        }
        present(addVC, animated: true)
    }
}

extension EventListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as? EventTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: todos[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let todo = todos[indexPath.row]

        let editVC = EditEventBottomSheetViewController()
        editVC.selectedDate = selectedDate
        editVC.todo = todo

        if let sheet = editVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        editVC.modalPresentationStyle = .pageSheet
        editVC.onEdit = { [self] todo in
            let vc = NewEventViewController()
                vc.selectedDate = selectedDate
                vc.existingTodo = todo
                vc.onSave = { updatedTodo in
                    EventManager.shared.deleteTodo(todo)
                    EventManager.shared.addTodo(updatedTodo)
                    self.loadTodos()
                }
                vc.onDelete = { deletedTodo in
                    EventManager.shared.deleteTodo(deletedTodo)
                    self.loadTodos()
                }

                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.medium()]
                    sheet.prefersGrabberVisible = true
                }
                vc.modalPresentationStyle = .pageSheet
            self.present(vc, animated: true)
        }
        editVC.onDelete = { todo in
            EventManager.shared.deleteTodo(todo)
            self.dismiss(animated: true)
            self.loadTodos()
        }
        if let sheet = editVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(editVC, animated: true)
    }
}
