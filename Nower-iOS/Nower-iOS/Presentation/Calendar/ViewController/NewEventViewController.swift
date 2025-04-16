//
//  NewEventViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/12/25.
//
import UIKit
import SnapKit

class NewEventViewController: UIViewController {

    private let contentView = NewEventView()
    var selectedDate: Date!
    var existingTodo: TodoItem?

    var onSave: ((TodoItem) -> Void)?
    var onDelete: ((TodoItem) -> Void)?

    private var selectedColorName: String = "skyblue"
    override func loadView() {
        self.view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let todo = existingTodo {
            contentView.eventTextField.text = todo.text
            selectedColorName = todo.colorName
            contentView.deleteButton.isHidden = false
            contentView.saveButton.setTitle("저장", for: .normal)
        }

        bindActions()
        highlightSelectedColor()
    }
    private func bindActions() {
        contentView.saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        contentView.deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)

        contentView.colorButtons.forEach { button in
            button.addTarget(self, action: #selector(colorSelected(_:)), for: .touchUpInside)
        }
    }

    @objc private func didTapSave() {
        guard let text = contentView.eventTextField.text, !text.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        let todo = TodoItem(
            id: existingTodo?.id ?? UUID(),
            text: text,
            isRepeating: false,
            date: dateString,
            colorName: selectedColorName
        )

        onSave?(todo)
        NotificationCenter.default.post(name: .init("TodosUpdated"), object: nil)
        dismiss(animated: true)
    }

    @objc private func didTapDelete() {
        guard let todo = existingTodo else { return }
        onDelete?(todo)
        NotificationCenter.default.post(name: .init("TodosUpdated"), object: nil)
        dismiss(animated: true)
    }

    @objc private func colorSelected(_ sender: UIButton) {
        let index = sender.tag
        selectedColorName = contentView.colors[index]

        contentView.colorButtons.forEach {
            $0.layer.borderColor = UIColor.lightGray.cgColor
        }
        sender.layer.borderColor = UIColor.black.cgColor
    }

    private func highlightSelectedColor() {
        guard let index = contentView.colors.firstIndex(of: selectedColorName) else { return }
        let button = contentView.colorButtons[index]
        button.layer.borderColor = UIColor.black.cgColor
    }
}
