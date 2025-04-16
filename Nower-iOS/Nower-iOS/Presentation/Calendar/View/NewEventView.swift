//
//  NewEventView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//

import UIKit

final class NewEventView: UIView {

    let eventTextField: UITextField = {
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

    var colorButtons: [UIButton] = []
    let colors: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white

        addSubview(eventTextField)

        eventTextField.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        addSubview(colorStackView)

        colorStackView.snp.makeConstraints {
            $0.top.equalTo(eventTextField.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        colors.enumerated().forEach { index, colorName in
            let button = UIButton()
            button.backgroundColor = AppColors.color(for: colorName)
            button.layer.cornerRadius = 8
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 1
            button.tag = index
            colorButtons.append(button)
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
}
