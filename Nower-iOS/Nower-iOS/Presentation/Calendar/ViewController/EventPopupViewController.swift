//
//  ViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit
import SnapKit

class EventPopupViewController: UIViewController {

    private let dateLabel = UILabel()
    private let tableView = UITableView()
    private var todos: [TodoItem]
    private let selectedDate: Date

    init(dateText: String, date: Date, todos: [TodoItem]) {
        self.selectedDate = date
        self.todos = todos
        super.init(nibName: nil, bundle: nil)
        dateLabel.text = dateText
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .white

        dateLabel.font = UIFont.boldSystemFont(ofSize: 20)
        dateLabel.textAlignment = .center

        view.addSubview(dateLabel)
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.centerX.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EventCell.self, forCellReuseIdentifier: EventCell.identifier)
    }
}

extension EventPopupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EventCell.identifier, for: indexPath) as? EventCell else {
            return UITableViewCell()
        }
        cell.configure(title: todos[indexPath.row].text)
        return cell
    }
}
