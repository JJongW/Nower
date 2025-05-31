//
//  NewEventView.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//

import UIKit

final class NewEventView: UIView {

    // MARK: - Components

    let textFieldBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "일정을 입력하세요"
        textField.setPlaceholder(color: AppColors.textFieldPlacehorder)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        return textField
    }()

    let colorStackView: UIStackView = {
        var stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 30
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

        addSubview(textFieldBackgroundView)
        addSubview(textField)

        textFieldBackgroundView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(36)
            $0.height.equalTo(60)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        textField.snp.makeConstraints {
            $0.center.equalTo(textFieldBackgroundView)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        addSubview(colorStackView)
        colorStackView.snp.makeConstraints {
            $0.top.equalTo(textFieldBackgroundView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(32)
            $0.height.equalTo(40)
        }

        for color in colorNames {
            let button = UIButton()
            button.backgroundColor = AppColors.color(for: color)
            button.layer.cornerRadius = 20
            button.layer.borderColor = AppColors.textHighlighted.cgColor
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
            button.layer.borderWidth = (button == sender) ? 3 : 0
            if button == sender {
                selectedColorName = colorNames[index]
            }
        }
    }
}
