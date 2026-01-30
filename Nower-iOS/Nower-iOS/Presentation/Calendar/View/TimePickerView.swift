//
//  TimePickerView.swift
//  Nower-iOS
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import UIKit
import SnapKit

final class TimePickerView: UIView {

    // MARK: - Callback

    var onTimeSelected: ((String?) -> Void)?

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
        label.text = "시간 선택"
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let allDayContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        return view
    }()

    private let allDayLabel: UILabel = {
        let label = UILabel()
        label.text = "하루 종일"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let allDaySwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        toggle.onTintColor = AppColors.color(for: "skyblue")
        return toggle
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko_KR")
        picker.minuteInterval = 5
        return picker
    }()

    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("확인", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = AppColors.textHighlighted
        button.layer.cornerRadius = 12
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        return button
    }()

    // MARK: - State

    private var isAllDay: Bool = true {
        didSet { updatePickerVisibility() }
    }

    // MARK: - Init

    init(currentTime: String? = nil) {
        super.init(frame: .zero)
        if let time = currentTime {
            isAllDay = false
            allDaySwitch.isOn = false
            let parts = time.split(separator: ":")
            if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = hour
                components.minute = minute
                if let date = Calendar.current.date(from: components) {
                    datePicker.date = date
                }
            }
        }
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
        containerView.addSubview(allDayContainer)
        allDayContainer.addSubview(allDayLabel)
        allDayContainer.addSubview(allDaySwitch)
        containerView.addSubview(datePicker)
        containerView.addSubview(confirmButton)
        containerView.addSubview(cancelButton)

        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        allDayContainer.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(52)
        }

        allDayLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        allDaySwitch.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        datePicker.snp.makeConstraints {
            $0.top.equalTo(allDayContainer.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(isAllDay ? 0 : 160)
        }

        confirmButton.snp.makeConstraints {
            $0.top.equalTo(datePicker.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }

        cancelButton.snp.makeConstraints {
            $0.top.equalTo(confirmButton.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().offset(-16)
        }

        datePicker.alpha = isAllDay ? 0 : 1

        allDaySwitch.addTarget(self, action: #selector(allDaySwitchChanged), for: .valueChanged)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        confirmButton.addPressAnimation()
    }

    // MARK: - Actions

    @objc private func allDaySwitchChanged() {
        isAllDay = allDaySwitch.isOn
    }

    @objc private func confirmTapped() {
        if isAllDay {
            onTimeSelected?(nil)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            onTimeSelected?(formatter.string(from: datePicker.date))
        }
        removeFromSuperview()
    }

    @objc private func cancelTapped() {
        removeFromSuperview()
    }

    @objc private func backgroundTapped() {
        removeFromSuperview()
    }

    // MARK: - Helpers

    private func updatePickerVisibility() {
        UIView.animate(withDuration: 0.3) {
            self.datePicker.alpha = self.isAllDay ? 0 : 1
            self.datePicker.snp.updateConstraints {
                $0.height.equalTo(self.isAllDay ? 0 : 160)
            }
            self.layoutIfNeeded()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TimePickerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self
    }
}
