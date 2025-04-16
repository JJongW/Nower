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
        view.addSubview(eventTableView)
        eventTableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let todo = todos[indexPath.row]

        let containerView = UIView()
        containerView.backgroundColor = AppColors.color(for: todo.colorName)
        containerView.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = todo.text
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "일상"
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .white

        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(10)
        }

        for subview in cell.contentView.subviews { subview.removeFromSuperview() }
        cell.contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(6)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        cell.backgroundColor = UIColor(hex: "#FFFFFF")
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
