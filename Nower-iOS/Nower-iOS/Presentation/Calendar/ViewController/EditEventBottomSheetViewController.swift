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

    /// 반복 일정 인스턴스의 발생 날짜 (가상 인스턴스의 date)
    var occurrenceDate: Date?

    private let popupView = NewEventView()

    override func loadView() {
        self.view = popupView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        popupView.setInitialSelectedDate(selectedDate)
        popupView.textField.text = todo.text
        popupView.saveButtonActiveTitle = "수정"
        popupView.updateSaveButtonState()
        popupView.deleteButton.isHidden = false

        // 색상 선택 (기존 색상 이름이 톤이 없는 경우 기본 톤으로 변환)
        let baseColorName = AppColors.baseColorName(from: todo.colorName)
        if popupView.colorNames.contains(baseColorName) {
            // 기존 색상이 톤이 있으면 그대로, 없으면 중간 톤(4)으로 설정
            if AppColors.toneNumber(from: todo.colorName) != nil {
                popupView.selectedColorName = todo.colorName
            } else {
                popupView.selectedColorName = "\(baseColorName)-4"
            }
        }
        
        // 기간별 일정인 경우 설정 (시간/알림 복원보다 먼저 호출)
        if todo.isPeriodEvent {
            popupView.isPeriodMode = true
            if let startDate = todo.startDateObject, let endDate = todo.endDateObject {
                popupView.setPeriodMode(true, startDate: startDate, endDate: endDate)
            }
        }

        // 시간/알림 설정 복원 (기간 모드 설정 이후에 호출해야 UI가 올바르게 반영됨)
        popupView.selectedScheduledTime = todo.scheduledTime
        popupView.selectedEndScheduledTime = todo.endScheduledTime
        popupView.selectedReminderMinutesBefore = todo.reminderMinutesBefore

        // 반복 설정 복원
        popupView.selectedRecurrenceInfo = todo.recurrenceInfo
        if todo.isRecurringEvent {
            // 반복 일정 편집 시 기간 모드 비활성화
            popupView.updateRecurrenceEnabled()
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
        guard let updatedText = popupView.textField.text, !updatedText.isEmpty else {
            // 빈 텍스트 에러 피드백
            popupView.shakeTextField()
            return
        }

        let updatedColor = popupView.selectedColorName
        let updatedTime = popupView.selectedScheduledTime
        let updatedEndTime = popupView.selectedEndScheduledTime
        let updatedReminder = popupView.selectedReminderMinutesBefore
        let updatedRecurrence = popupView.selectedRecurrenceInfo

        // 알림 설정 시 권한 요청
        if updatedReminder != nil {
            Task {
                let granted = await LocalNotificationManager.shared.requestPermission()
                if !granted {
                    await MainActor.run {
                        self.showAlert(title: "알림 권한", message: "알림을 받으려면 설정에서 알림 권한을 허용해주세요.")
                    }
                }
            }
        }

        // 반복 일정인 경우 scope 액션 시트 표시
        if todo.isRecurringEvent {
            showRecurrenceScopeSheet { [weak self] scope in
                guard let self = self else { return }
                let updated = TodoItem(
                    text: updatedText,
                    isRepeating: updatedRecurrence != nil,
                    date: self.todo.date,
                    colorName: updatedColor,
                    scheduledTime: updatedTime,
                    reminderMinutesBefore: updatedReminder,
                    recurrenceInfo: updatedRecurrence
                )
                self.viewModel.updateRecurringTodo(
                    original: self.todo,
                    updated: updated,
                    occurrenceDate: self.occurrenceDate ?? self.selectedDate,
                    scope: scope
                )
                self.popupView.triggerSuccessFeedback()
                self.dismissAndRefresh(message: "반복 일정이 수정되었습니다")
            }
            return
        }

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

            viewModel.updatePeriodTodo(original: todo, updatedText: updatedText, updatedColor: updatedColor, startDate: startDate, endDate: endDate, scheduledTime: updatedTime, endScheduledTime: updatedEndTime, reminderMinutesBefore: updatedReminder)
        } else {
            // 단일 날짜 일정으로 변경
            viewModel.updateTodo(original: todo, updatedText: updatedText, updatedColor: updatedColor, date: selectedDate, scheduledTime: updatedTime, reminderMinutesBefore: updatedReminder)
        }

        // 성공 햅틱 피드백
        popupView.triggerSuccessFeedback()
        dismissAndRefresh(message: "일정이 수정되었습니다")
    }

    private func dismissAndRefresh(message: String) {
        dismiss(animated: true) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("CloudSyncManager.todosDidUpdate"), object: nil)
            }

            if let vc = self.coordinator?.navigationController.topViewController {
                vc.showToast(message: message)
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
        // 반복 일정인 경우 scope 액션 시트 표시
        if todo.isRecurringEvent {
            showRecurrenceScopeSheet { [weak self] scope in
                guard let self = self else { return }
                self.viewModel.deleteRecurringTodo(
                    self.todo,
                    occurrenceDate: self.occurrenceDate ?? self.selectedDate,
                    scope: scope
                )
                self.dismissAndRefresh(message: "반복 일정이 삭제되었습니다")
            }
            return
        }

        // 일반 일정 삭제 확인 다이얼로그
        let alert = UIAlertController(
            title: "일정 삭제",
            message: "'\(todo.text)'을(를) 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })

        present(alert, animated: true)
    }

    private func performDelete() {
        viewModel.deleteTodo(todo)
        dismiss(animated: true) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("CloudSyncManager.todosDidUpdate"), object: nil)

                if let vc = self.coordinator?.navigationController.topViewController {
                    vc.showToast(message: "일정이 삭제되었습니다")
                }
                self.coordinator?.returnToBack()
            }
        }
    }

    // MARK: - Recurrence Scope Sheet

    private func showRecurrenceScopeSheet(completion: @escaping (RecurrenceEditScope) -> Void) {
        let alert = UIAlertController(
            title: "반복 일정",
            message: "어떤 일정에 적용하시겠습니까?",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "이 일정만", style: .default) { _ in
            completion(.thisOnly)
        })
        alert.addAction(UIAlertAction(title: "이 일정 및 향후 일정", style: .default) { _ in
            completion(.thisAndFuture)
        })
        alert.addAction(UIAlertAction(title: "모든 일정", style: .destructive) { _ in
            completion(.all)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad 팝오버 지원
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
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
