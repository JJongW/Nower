//
//  RecurrencePickerView.swift
//  Nower-iOS
//
//  반복 일정 설정을 위한 빠른 선택 피커 뷰
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import UIKit
import SnapKit

final class RecurrencePickerView: UIView {

    // MARK: - Callback

    var onRecurrenceSelected: ((RecurrenceInfo?) -> Void)?
    var onCustomRequested: (() -> Void)?

    // MARK: - Data

    struct RecurrenceOption {
        let title: String
        let info: RecurrenceInfo?
        let isCustom: Bool

        init(title: String, info: RecurrenceInfo?, isCustom: Bool = false) {
            self.title = title
            self.info = info
            self.isCustom = isCustom
        }
    }

    private let options: [RecurrenceOption] = [
        RecurrenceOption(title: "안 함", info: nil),
        RecurrenceOption(title: "매일", info: RecurrenceInfo(frequency: "daily")),
        RecurrenceOption(title: "매주", info: RecurrenceInfo(frequency: "weekly")),
        RecurrenceOption(title: "평일 (월~금)", info: RecurrenceInfo(frequency: "weekly", daysOfWeek: [2, 3, 4, 5, 6])),
        RecurrenceOption(title: "매월", info: RecurrenceInfo(frequency: "monthly")),
        RecurrenceOption(title: "매년", info: RecurrenceInfo(frequency: "yearly")),
        RecurrenceOption(title: "사용자 설정...", info: nil, isCustom: true),
    ]

    private var selectedInfo: RecurrenceInfo?

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
        label.text = "반복"
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

    init(currentInfo: RecurrenceInfo? = nil) {
        self.selectedInfo = currentInfo
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

    private func createOptionRow(option: RecurrenceOption, index: Int) -> UIView {
        let container = UIView()

        let button = UIButton(type: .system)
        button.tag = index
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)

        let label = UILabel()
        label.text = option.title
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = option.isCustom ? AppColors.textHighlighted : AppColors.textPrimary

        let checkmark = UILabel()
        checkmark.text = "\u{2713}"
        checkmark.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        checkmark.textColor = AppColors.textHighlighted

        let isSelected: Bool
        if option.isCustom {
            isSelected = false
        } else if let info = option.info {
            isSelected = selectedInfo?.frequency == info.frequency && selectedInfo?.interval == info.interval && selectedInfo?.daysOfWeek == info.daysOfWeek
        } else {
            isSelected = selectedInfo == nil
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

        // 접근성
        button.accessibilityLabel = option.title
        if isSelected {
            button.accessibilityTraits = [.button, .selected]
        }

        return container
    }

    // MARK: - Actions

    @objc private func optionTapped(_ sender: UIButton) {
        let option = options[sender.tag]
        if option.isCustom {
            onCustomRequested?()
            removeFromSuperview()
        } else {
            onRecurrenceSelected?(option.info)
            removeFromSuperview()
        }
    }

    @objc private func backgroundTapped() {
        removeFromSuperview()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension RecurrencePickerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self
    }
}
