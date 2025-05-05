//
//  EditEventBottomSheetViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//
import UIKit

final class EditEventBottomSheetViewController: UIViewController {
    var todo: TodoItem!
    var selectedDate: Date!
    var viewModel: CalendarViewModel!  // ✅ 이게 반드시 있어야 함

    private let popupView = NewEventView()

    override func loadView() {
        self.view = popupView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        popupView.textField.text = todo.text
        popupView.dateLabel.text = selectedDate.formatted("yy.MM.dd")
        popupView.deleteButton.isHidden = false

        if let index = popupView.colorOptions.firstIndex(where: {
            AppColors.color(for: popupView.colorNames[$0.tag]) == AppColors.color(for: todo.colorName)
        }) {
            popupView.selectColor(popupView.colorOptions[index])
        }

        popupView.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        popupView.deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        popupView.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        popupView.colorOptions.forEach {
            $0.addTarget(self, action: #selector(colorSelected(_:)), for: .touchUpInside)
        }
    }

    @objc private func saveTapped() {
        guard let updatedText = popupView.textField.text, !updatedText.isEmpty else { return }

        let updatedColor = popupView.selectedColorName
        viewModel.updateTodo(original: todo, updatedText: updatedText, updatedColor: updatedColor)

        dismiss(animated: true)
    }

    @objc private func deleteTapped() {
        viewModel.deleteTodo(todo)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func colorSelected(_ sender: UIButton) {
        popupView.selectColor(sender)
    }
}
