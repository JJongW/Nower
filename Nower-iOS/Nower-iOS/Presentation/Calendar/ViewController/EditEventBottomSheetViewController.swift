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
        popupView.saveButton.setTitle("수정", for: .normal)
        popupView.deleteButton.isHidden = false

        // 색상 선택
        if let index = popupView.colorOptions.firstIndex(where: {
            AppColors.color(for: popupView.colorNames[$0.tag]) == AppColors.color(for: todo.colorName)
        }) {
            popupView.selectColor(popupView.colorOptions[index])
        }
        
        // 기간별 일정인 경우 설정
        if todo.isPeriodEvent {
            popupView.isPeriodMode = true
            if let startDate = todo.startDateObject, let endDate = todo.endDateObject {
                // 기간별 일정인 경우: 시작일은 원래 일정의 시작일, 종료일은 원래 일정의 종료일
                // 단, selectedDate가 있다면 시작일은 selectedDate로 설정
                let initialStartDate = selectedDate != nil ? selectedDate! : startDate
                popupView.setPeriodMode(true, startDate: initialStartDate, endDate: endDate)
            }
        }

        popupView.saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        popupView.deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        popupView.periodModeSwitch.addTarget(self, action: #selector(periodModeChanged), for: .valueChanged)
        popupView.startDateButton.addTarget(self, action: #selector(startDateButtonTapped), for: .touchUpInside)
        popupView.endDateButton.addTarget(self, action: #selector(endDateButtonTapped), for: .touchUpInside)
        popupView.colorOptions.forEach {
            $0.addTarget(self, action: #selector(colorSelected(_:)), for: .touchUpInside)
        }
    }
    
    @objc private func periodModeChanged() {
        // 기간 모드 변경 시 날짜 초기화
        if popupView.isPeriodMode {
            if popupView.selectedStartDate == nil {
                popupView.selectedStartDate = selectedDate ?? Date()
            }
            if popupView.selectedEndDate == nil {
                popupView.selectedEndDate = popupView.selectedStartDate
            }
        }
    }
    
    @objc private func startDateButtonTapped() {
        // DatePicker는 NewEventView에서 처리됨
    }
    
    @objc private func endDateButtonTapped() {
        // DatePicker는 NewEventView에서 처리됨
    }

    @objc private func saveTapped() {
        guard let updatedText = popupView.textField.text, !updatedText.isEmpty else { return }

        let updatedColor = popupView.selectedColorName
        
        // 기간별 일정 처리
        if popupView.isPeriodMode {
            guard let startDate = popupView.selectedStartDate,
                  let endDate = popupView.selectedEndDate else {
                showAlert(title: "알림", message: "시작일과 종료일을 모두 선택해주세요.")
                return
            }
            
            if startDate > endDate {
                showAlert(title: "알림", message: "시작일은 종료일보다 이전이어야 합니다.")
                return
            }
            
            viewModel.updatePeriodTodo(original: todo, updatedText: updatedText, updatedColor: updatedColor, startDate: startDate, endDate: endDate)
        } else {
            // 단일 날짜 일정으로 변경
            viewModel.updateTodo(original: todo, updatedText: updatedText, updatedColor: updatedColor, date: selectedDate)
        }
        
        dismiss(animated: true) {
            // 일정 수정 후 즉시 UI 새로고침을 위한 수동 알림 발송
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("CloudSyncManager.todosDidUpdate"), object: nil)
            }
            
            if let vc = self.coordinator?.navigationController.topViewController {
                vc.showToast(message: "🛠️ 일정이 수정되었습니다")
            }
            self.coordinator?.returnToBack()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func deleteTapped() {
        viewModel.deleteTodo(todo)
        dismiss(animated: true) {
            // 일정 삭제 후 즉시 UI 새로고침을 위한 수동 알림 발송
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("CloudSyncManager.todosDidUpdate"), object: nil)
                
                if let vc = self.coordinator?.navigationController.topViewController {
                    #if DEBUG
                    print("일정 삭제됨.")
                    #endif
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
