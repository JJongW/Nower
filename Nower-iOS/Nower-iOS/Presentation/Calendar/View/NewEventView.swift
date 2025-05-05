//
//  NewEventView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//

import UIKit

final class NewEventView: UIView {

    // MARK: - Components

    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.systemGray, for: .normal)
        return button
    }()

    let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "일정을 입력하세요"
        textField.setPlaceholder(color: AppColors.textPrimary)
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .white
        textField.textColor = AppColors.textPrimary
        textField.tintColor = AppColors.textPrimary
        return textField
    }()

    let colorStackView: UIStackView = {
        var stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        return stackView
    }()

    let saveButton = UIButton(type: .system)
    let deleteButton = UIButton(type: .system)

    private(set) var colorOptions: [UIButton] = []
    private(set) var selectedColorName: String = "skyblue"
    let colorNames: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        backgroundColor = .white

        addSubview(dateLabel)
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(12)
            $0.centerX.equalToSuperview()
        }

        addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.centerY.equalTo(dateLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        addSubview(textField)
        textField.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        addSubview(colorStackView)
        colorStackView.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        for color in colorNames {
            let button = UIButton()
            button.backgroundColor = AppColors.color(for: color)
            button.layer.cornerRadius = 8
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 1
            button.tag = colorOptions.count
            colorOptions.append(button)
            colorStackView.addArrangedSubview(button)
        }

        addSubview(saveButton)
        saveButton.setTitle("추가", for: .normal)
        saveButton.snp.makeConstraints {
            $0.top.equalTo(colorStackView.snp.bottom).offset(30)
            $0.centerX.equalToSuperview()
        }

        addSubview(deleteButton)
        deleteButton.setTitle("삭제", for: .normal)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        deleteButton.isHidden = true
    }

    func selectColor(_ sender: UIButton) {
        for (index, button) in colorOptions.enumerated() {
            button.layer.borderWidth = (button == sender) ? 3 : 1
            if button == sender {
                selectedColorName = colorNames[index]
            }
        }
    }
}
