//
//  ViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit
import SnapKit

final class EventPopupViewController: UIViewController {

    var selectedDate: Date!
    var onSave: ((TodoItem) -> Void)?

    private let popupView = NewEventView()
    private let viewModel: CalendarViewModel

    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        let colorName = popupView.selectedColorName

        viewModel.todoText = text
        viewModel.selectedColorName = colorName
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
