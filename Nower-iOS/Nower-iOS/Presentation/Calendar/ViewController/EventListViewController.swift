//
//  EventListViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//
import UIKit

final class EventListViewController: UIViewController {
    var selectedDate: Date!
    var viewModel: CalendarViewModel!

    private let eventDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let eventTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColors.background
        tableView.register(EventTableViewCell.self, forCellReuseIdentifier: "EventCell")
        return tableView
    }()

    private let addButton: UIButton = {
        let button = UIButton()
        button.setTitle("＋", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        button.backgroundColor = AppColors.textPrimary
        button.tintColor = .white
        button.layer.cornerRadius = 25
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reload()
    }

    private func setupUI() {
        view.backgroundColor = .white
        eventTableView.dataSource = self
        eventTableView.delegate = self

        view.addSubview(eventDateLabel)
        view.addSubview(eventTableView)
        view.addSubview(addButton)

        eventDateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.leading.equalToSuperview().offset(20)
        }

        eventTableView.snp.makeConstraints {
            $0.top.equalTo(eventDateLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(50)
        }

        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
    }

    private func reload() {
        viewModel.selectedDate = selectedDate
        viewModel.loadAllTodos()
        eventTableView.reloadData()
        eventDateLabel.text = selectedDate.formatted("yy.MM.dd")
    }

    @objc private func didTapAdd() {
        let newVC = NewEventViewController()
        newVC.selectedDate = selectedDate
        newVC.viewModel = viewModel

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

        if let sheet = editVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(editVC, animated: true)
    }
}
