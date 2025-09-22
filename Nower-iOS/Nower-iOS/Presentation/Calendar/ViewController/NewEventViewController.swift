//
//  NewEventViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/12/25.
//
import UIKit
import SnapKit

final class NewEventViewController: UIViewController {
    var coordinator: AppCoordinator?
    var selectedDate: Date!
    var viewModel: CalendarViewModel!

    private let popupView = NewEventView()

    override func loadView() {
        self.view = popupView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        popupView.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        popupView.colorOptions.forEach { button in
            button.addTarget(self, action: #selector(colorSelected(_:)), for: .touchUpInside)
        }
    }

    @objc private func saveTapped() {
        guard let text = popupView.textField.text, !text.isEmpty else { return }

        viewModel.todoText = text
        viewModel.selectedColorName = popupView.selectedColorName
        
        // 기간별 일정 처리
        if popupView.isPeriodMode {
            // 기간별 일정인 경우
            guard let startDate = popupView.selectedStartDate,
                  let endDate = popupView.selectedEndDate else {
                // 날짜가 선택되지 않은 경우 경고
                showAlert(title: "알림", message: "시작일과 종료일을 모두 선택해주세요.")
                return
            }
            
            if startDate > endDate {
                showAlert(title: "알림", message: "시작일은 종료일보다 이전이어야 합니다.")
                return
            }
            
            viewModel.selectedStartDate = startDate
            viewModel.selectedEndDate = endDate
            viewModel.addPeriodTodo()
        } else {
            // 단일 날짜 일정인 경우 (기존 로직)
            viewModel.selectedDate = selectedDate
            viewModel.addTodo()
        }

        dismiss(animated: true) {
            // 일정 추가 후 즉시 UI 새로고침을 위한 수동 알림 발송
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("CloudSyncManager.todosDidUpdate"), object: nil)
            }
            
            if let vc = self.coordinator?.navigationController.topViewController {
                let message = self.popupView.isPeriodMode ? "✅ 기간별 일정이 추가되었습니다" : "✅ 일정이 추가되었습니다"
                vc.showToast(message: message)
            }
            self.coordinator?.returnToBack()
        }
    }
    
    /// 알림 다이얼로그를 표시합니다.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func colorSelected(_ sender: UIButton) {
        popupView.selectColor(sender)
    }
}
