//
//  EventTableViewCell.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/20/25.
//

import UIKit

class EventTableViewCell: UITableViewCell {

    private let eventTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "일정"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColors.textMain
        label.numberOfLines = 1
        return label
    }()

    private let eventSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "일상"
        label.font = .systemFont(ofSize: 12)
        label.textColor = AppColors.textMain
        return label
    }()

    private let containerView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColors.background
        contentView.addSubview(containerView)
        containerView.addSubview(eventTitleLabel)
        containerView.addSubview(eventSubtitleLabel)

        containerView.layer.cornerRadius = 12

        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(4)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        eventTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        eventSubtitleLabel.snp.makeConstraints {
            $0.top.equalTo(eventTitleLabel.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    func configure(with todo: TodoItem) {
        containerView.backgroundColor = AppColors.color(for: todo.colorName)
        eventTitleLabel.text = todo.text
        eventSubtitleLabel.text = "일상"
    }
}
