//
//  NewEventViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/12/25.
//
import UIKit
import SnapKit

class NewEventViewController: UIViewController {

    var selectedDate: Date!
    var onSave: ((TodoItem) -> Void)?

    private let textField = UITextField()
    private var selectedColorName: String = "skyblue"

    private let colors: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]
    private let colorStackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        view.addSubview(textField)
        textField.placeholder = "일정을 입력하세요"
        textField.borderStyle = .roundedRect
        textField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        view.addSubview(colorStackView)
        colorStackView.axis = .horizontal
        colorStackView.spacing = 8
        colorStackView.distribution = .fillEqually
        colorStackView.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        colors.forEach { colorName in
            let button = UIButton()
            button.backgroundColor = UIColor(AppColors.color(for: colorName))
            button.layer.cornerRadius = 8
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 1
            button.tag = colors.firstIndex(of: colorName) ?? 0
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            colorStackView.addArrangedSubview(button)
        }

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("추가", for: .normal)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints {
            $0.top.equalTo(colorStackView.snp.bottom).offset(30)
            $0.centerX.equalToSuperview()
        }
    }

    @objc private func colorButtonTapped(_ sender: UIButton) {
        selectedColorName = colors[sender.tag]
        colorStackView.arrangedSubviews.forEach { view in
            if let button = view as? UIButton {
                button.layer.borderColor = UIColor.lightGray.cgColor
            }
        }
        sender.layer.borderColor = UIColor.black.cgColor
    }

    @objc private func didTapSave() {
        guard let text = textField.text, !text.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        let newTodo = TodoItem(
            text: text,
            isRepeating: false,
            date: dateString,
            colorName: selectedColorName
        )

        onSave?(newTodo)
        dismiss(animated: true)
    }
}
