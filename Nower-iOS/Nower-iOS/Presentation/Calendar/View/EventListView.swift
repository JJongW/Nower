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
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textFieldPlaceholder
        label.textAlignment = .center
        label.text = "" // 동적으로 설정
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
        button.titleLabel?.font = .systemFont(ofSize: 32, weight: .bold)
        // 강조 색상으로 변경하여 더 잘 보이게
        button.backgroundColor = AppColors.textHighlighted
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 28
        // 그림자 추가로 더 눈에 띄게
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.3
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
        backgroundColor = AppColors.background

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
            $0.width.height.equalTo(56) // 더 크게 (최소 터치 타겟 44pt + 여유)
        }
    }
}
