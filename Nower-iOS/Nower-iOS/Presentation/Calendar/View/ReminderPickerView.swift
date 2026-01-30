//
//  ReminderPickerView.swift
//  Nower-iOS
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import UIKit
import SnapKit

final class ReminderPickerView: UIView {

    // MARK: - Callback

    var onReminderSelected: ((Int?) -> Void)?

    // MARK: - Data

    struct ReminderOption {
        let title: String
        let minutes: Int? // nil = 없음
    }

    private let options: [ReminderOption] = [
        ReminderOption(title: "없음", minutes: nil),
        ReminderOption(title: "정시", minutes: 0),
        ReminderOption(title: "5분 전", minutes: 5),
        ReminderOption(title: "10분 전", minutes: 10),
        ReminderOption(title: "30분 전", minutes: 30),
        ReminderOption(title: "1시간 전", minutes: 60),
        ReminderOption(title: "1일 전", minutes: 1440),
    ]

    private var selectedMinutes: Int?

    // MARK: - Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.popupBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "알림"
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    // MARK: - Init

    init(currentMinutes: Int? = nil) {
        self.selectedMinutes = currentMinutes
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)

        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(stackView)

        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-8)
        }

        for (index, option) in options.enumerated() {
            let row = createOptionRow(option: option, index: index)
            stackView.addArrangedSubview(row)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }

    private func createOptionRow(option: ReminderOption, index: Int) -> UIView {
        let container = UIView()

        let button = UIButton(type: .system)
        button.tag = index
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)

        let label = UILabel()
        label.text = option.title
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = AppColors.textPrimary

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        checkmark.textColor = AppColors.textHighlighted

        let isSelected: Bool
        if let minutes = option.minutes {
            isSelected = selectedMinutes == minutes
        } else {
            isSelected = selectedMinutes == nil
        }
        checkmark.isHidden = !isSelected

        container.addSubview(label)
        container.addSubview(checkmark)
        container.addSubview(button)

        container.snp.makeConstraints {
            $0.height.equalTo(48)
        }

        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }

        checkmark.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
        }

        button.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        return container
    }

    // MARK: - Actions

    @objc private func optionTapped(_ sender: UIButton) {
        let option = options[sender.tag]
        onReminderSelected?(option.minutes)
        removeFromSuperview()
    }

    @objc private func backgroundTapped() {
        removeFromSuperview()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ReminderPickerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self
    }
}
