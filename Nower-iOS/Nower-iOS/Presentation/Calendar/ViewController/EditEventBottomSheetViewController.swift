//
//  EditEventBottomSheetViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//
import UIKit

final class EditEventBottomSheetViewController: UIViewController {
    var coordinator: AppCoordinator?
    var todo: TodoItem!
    var selectedDate: Date!
    var viewModel: CalendarViewModel!

    private let popupView = NewEventView()

    override func loadView() {
        self.view = popupView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        popupView.textField.text = todo.text
        popupView.deleteButton.isHidden = false

        if let index = popupView.colorOptions.firstIndex(where: {
            AppColors.color(for: popupView.colorNames[$0.tag]) == AppColors.color(for: todo.colorName)
        }) {
            popupView.selectColor(popupView.colorOptions[index])
        }

        popupView.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        popupView.deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        popupView.colorOptions.forEach {
            $0.addTarget(self, action: #selector(colorSelected(_:)), for: .touchUpInside)
        }
    }

    @objc private func saveTapped() {
        guard let updatedText = popupView.textField.text, !updatedText.isEmpty else { return }

        let updatedColor = popupView.selectedColorName
        viewModel.updateTodo(original: todo, updatedText: updatedText, updatedColor: updatedColor)
        dismiss(animated: true) {
            if let vc = self.coordinator?.navigationController.topViewController {
                vc.showToast(message: "🛠️ 일정이 수정되었습니다")
            }
            self.coordinator?.returnToBack()
        }
    }

    @objc private func deleteTapped() {
        viewModel.deleteTodo(todo)
        dismiss(animated: true) {
            DispatchQueue.main.async {
                if let vc = self.coordinator?.navigationController.topViewController {
                    print("일정 삭제됨.")
                    vc.showToast(message: "❌ 일정이 삭제되었습니다")
                }
                self.coordinator?.returnToBack()
            }
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.coordinator?.returnToBack()
        }
    }

    @objc private func colorSelected(_ sender: UIButton) {
        popupView.selectColor(sender)
    }
}
