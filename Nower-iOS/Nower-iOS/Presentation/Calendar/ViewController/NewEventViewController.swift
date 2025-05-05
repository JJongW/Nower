//
//  NewEventViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/12/25.
//
import UIKit
import SnapKit

final class NewEventViewController: UIViewController {
    var selectedDate: Date!
    var viewModel: CalendarViewModel!  // ✅ 여기에 선언이 있어야 함

    private let popupView = NewEventView()

    override func loadView() {
        self.view = popupView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        popupView.dateLabel.text = selectedDate.formatted("yy.MM.dd")

        popupView.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        popupView.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        popupView.colorOptions.forEach { button in
            button.addTarget(self, action: #selector(colorSelected(_:)), for: .touchUpInside)
        }
    }

    @objc private func saveTapped() {
        guard let text = popupView.textField.text, !text.isEmpty else { return }

        viewModel.todoText = text
        viewModel.selectedColorName = popupView.selectedColorName
        viewModel.selectedDate = selectedDate
        viewModel.addTodo()

        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func colorSelected(_ sender: UIButton) {
        popupView.selectColor(sender)
    }
}
