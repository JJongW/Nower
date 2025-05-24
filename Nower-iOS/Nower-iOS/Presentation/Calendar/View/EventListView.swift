//
//  EventListView.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/24/25.
//

import UIKit


final class EventListView: UIView {

    let eventDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppColors.textPrimary
        return label
    }()

    let eventWeekLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .light)
        label.textColor = AppColors.textPrimary
        return label
    }()

    let eventLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.text = "Today"
        return label
    }()

    let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.text = "     "
        return label
    }()

    private let dateStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()

    private let mainStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }()

    let eventTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColors.background
        tableView.register(EventTableViewCell.self, forCellReuseIdentifier: "EventCell")
        return tableView
    }()

    let addButton: UIButton = {
        let button = UIButton()
        button.setTitle("＋", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        button.backgroundColor = AppColors.textPrimary
        button.tintColor = .white
        button.layer.cornerRadius = 25
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white

        addSubview(eventDateLabel)
        addSubview(eventTableView)
        addSubview(addButton)

        dateStack.addArrangedSubview(eventDateLabel)
        dateStack.addArrangedSubview(eventWeekLabel)

        mainStack.addArrangedSubview(dateStack)
        mainStack.addArrangedSubview(eventLabel)
        mainStack.addArrangedSubview(emptyLabel)

        addSubview(mainStack)

        mainStack.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        eventTableView.snp.makeConstraints {
            $0.top.equalTo(mainStack.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(50)
        }
    }
}
