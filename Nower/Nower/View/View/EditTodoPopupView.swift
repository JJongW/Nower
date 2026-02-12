//
//  EditTodoPopupView.swift
//  Nower
//
//  Created by 신종원 on 3/29/25.
//  Redesigned for macOS Apple Calendar-style UX on 2026/02/10.
//

import SwiftUI

struct EditTodoPopupView: View {
    let originalTodo: TodoItem
    let date: String
    @Binding var isPresented: Bool

    @EnvironmentObject var viewModel: CalendarViewModel

    @State private var editedText: String
    @State private var selectedColorName: String
    @State private var editStartDate: Date
    @State private var editEndDate: Date
    @State private var isPeriodEventEditing: Bool
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    @State private var showDeleteConfirmation: Bool = false
    @State private var showColorVariationPicker: Bool = false
    @State private var selectedBaseColor: String = "skyblue"

    // 반복 관련 상태
    @State private var showRecurrenceScopeForSave: Bool = false
    @State private var showRecurrenceScopeForDelete: Bool = false
    @State private var selectedRecurrence: RecurrenceInfo?
    @State private var showCustomRecurrence: Bool = false

    // 시간/알림 상태
    @State private var hasTime: Bool
    @State private var selectedTime: Date
    @State private var hasReminder: Bool
    @State private var reminderMinutes: Int

    /// 반복 일정 인스턴스의 발생 날짜
    var occurrenceDate: Date?

    let colorOptions: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]

    let recurrencePresets: [(label: String, info: RecurrenceInfo?)] = [
        ("안 함", nil),
        ("매일", RecurrenceInfo(frequency: "daily")),
        ("매주", RecurrenceInfo(frequency: "weekly")),
        ("평일 (월~금)", RecurrenceInfo(frequency: "weekly", daysOfWeek: [2, 3, 4, 5, 6])),
        ("매월", RecurrenceInfo(frequency: "monthly")),
        ("매년", RecurrenceInfo(frequency: "yearly"))
    ]

    let reminderOptions: [(label: String, minutes: Int)] = [
        ("정시", 0),
        ("5분 전", 5),
        ("10분 전", 10),
        ("30분 전", 30),
        ("1시간 전", 60),
        ("하루 전", 1440)
    ]

    init(todo: TodoItem, date: String, isPresented: Binding<Bool>, showToast: Binding<Bool>, toastMessage: Binding<String>, occurrenceDate: Date? = nil) {
        self.originalTodo = todo
        self.date = date
        self._isPresented = isPresented
        self._showToast = showToast
        self._toastMessage = toastMessage
        self.occurrenceDate = occurrenceDate
        _editedText = State(initialValue: todo.text)
        _selectedColorName = State(initialValue: todo.colorName)
        _isPeriodEventEditing = State(initialValue: todo.isPeriodEvent)
        _editStartDate = State(initialValue: todo.startDateObject ?? Date())
        _editEndDate = State(initialValue: todo.endDateObject ?? Date())
        _selectedRecurrence = State(initialValue: todo.recurrenceInfo)

        // 시간/알림 복원
        if let time = todo.scheduledTime {
            _hasTime = State(initialValue: true)
            let parts = time.split(separator: ":")
            if parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) {
                let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                _selectedTime = State(initialValue: date)
            } else {
                _selectedTime = State(initialValue: Date())
            }
        } else {
            _hasTime = State(initialValue: false)
            _selectedTime = State(initialValue: Date())
        }

        if let minutes = todo.reminderMinutesBefore {
            _hasReminder = State(initialValue: true)
            _reminderMinutes = State(initialValue: minutes)
        } else {
            _hasReminder = State(initialValue: false)
            _reminderMinutes = State(initialValue: 0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("일정 편집")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        if originalTodo.isRecurringEvent {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textHighlighted)
                        }
                    }
                    Text(dateContextString)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 제목
                    formRow(label: "제목") {
                        TextField("일정 내용", text: $editedText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AppColors.textFieldBackground)
                            .cornerRadius(6)
                    }

                    // 색상 선택
                    formRow(label: "색상") {
                        HStack(spacing: 8) {
                            ForEach(colorOptions, id: \.self) { color in
                                colorButton(for: color)
                            }
                        }
                        .popover(isPresented: $showColorVariationPicker, arrowEdge: .bottom) {
                            ColorVariationPickerView(
                                baseColorName: selectedBaseColor,
                                selectedTone: AppColors.toneNumber(from: selectedColorName),
                                onColorSelected: { colorName in
                                    selectedColorName = colorName
                                    showColorVariationPicker = false
                                }
                            )
                        }
                    }

                    Divider().padding(.horizontal, -4)

                    // 기간별 일정 수정 UI
                    if isPeriodEventEditing {
                        formRow(label: "시작일") {
                            DatePicker("", selection: $editStartDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        formRow(label: "종료일") {
                            DatePicker("", selection: $editEndDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        if editStartDate > editEndDate {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppColors.coralred)
                                    .font(.system(size: 11))
                                Text("시작일은 종료일보다 이전이어야 합니다")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColors.coralred)
                            }
                            .padding(.leading, 92)
                        }
                    }

                    // 시간 — Apple Calendar 스타일
                    formRow(label: "시간") {
                        if hasTime {
                            HStack(spacing: 8) {
                                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(width: 90)
                                Button(action: { hasTime = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textFieldPlaceholder)
                                }
                                .buttonStyle(.borderless)
                                .help("하루 종일로 변경")
                            }
                        } else {
                            menuButton(title: "하루 종일") {
                                hasTime = true
                            }
                        }
                    }

                    // 반복 설정 (기간 일정이 아닌 경우만)
                    if !isPeriodEventEditing {
                        formRow(label: "반복") {
                            Menu {
                                ForEach(Array(recurrencePresets.enumerated()), id: \.offset) { index, preset in
                                    Button(action: { selectedRecurrence = preset.info }) {
                                        HStack {
                                            Text(preset.label)
                                            if isRecurrenceEqual(selectedRecurrence, preset.info) {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                                Divider()
                                Button("사용자 설정...") { showCustomRecurrence = true }
                            } label: {
                                menuLabel(text: recurrenceDisplayText)
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                    }

                    // 알림 — Apple Calendar 스타일
                    formRow(label: "알림") {
                        if hasReminder {
                            HStack(spacing: 8) {
                                Picker("", selection: $reminderMinutes) {
                                    ForEach(reminderOptions, id: \.minutes) { option in
                                        Text(option.label).tag(option.minutes)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .fixedSize()
                                Button(action: { hasReminder = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textFieldPlaceholder)
                                }
                                .buttonStyle(.borderless)
                                .help("알림 해제")
                            }
                        } else {
                            menuButton(title: "없음") {
                                hasReminder = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }

            Divider()

            // 하단 버튼 바
            HStack {
                // 삭제 버튼 (왼쪽)
                if originalTodo.isRecurringEvent {
                    Button(action: { showRecurrenceScopeForDelete = true }) {
                        Text("삭제")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(AppColors.coralred)
                } else {
                    Button(action: { showDeleteConfirmation = true }) {
                        Text("삭제")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(AppColors.coralred)
                    .alert("일정 삭제", isPresented: $showDeleteConfirmation) {
                        Button("취소", role: .cancel) { }
                        Button("삭제", role: .destructive) { performDelete() }
                    } message: {
                        Text("'\(originalTodo.text)'을(를) 삭제하시겠습니까?")
                    }
                }

                Spacer()

                Button("취소") { isPresented = false }
                    .keyboardShortcut(.escape)
                    .buttonStyle(.bordered)

                if originalTodo.isRecurringEvent {
                    Button("저장") { showRecurrenceScopeForSave = true }
                        .keyboardShortcut(.return, modifiers: .command)
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("저장") { saveChanges() }
                        .keyboardShortcut(.return, modifiers: .command)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 420, height: dynamicHeight)
        .background(AppColors.popupBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            selectedBaseColor = AppColors.baseColorName(from: selectedColorName)
            if AppColors.toneNumber(from: selectedColorName) == nil {
                selectedColorName = "\(selectedColorName)-4"
            }
        }
        .sheet(isPresented: $showCustomRecurrence) {
            CustomRecurrenceSheet(
                initialInfo: selectedRecurrence,
                onSave: { info in
                    selectedRecurrence = info
                    showCustomRecurrence = false
                },
                onCancel: { showCustomRecurrence = false }
            )
        }
        .confirmationDialog("반복 일정 수정", isPresented: $showRecurrenceScopeForSave, titleVisibility: .visible) {
            Button("이 일정만") { saveWithScope(.thisOnly) }
            Button("이 일정 및 향후 일정") { saveWithScope(.thisAndFuture) }
            Button("모든 일정") { saveWithScope(.all) }
            Button("취소", role: .cancel) { }
        } message: {
            Text("어떤 일정에 적용하시겠습니까?")
        }
        .confirmationDialog("반복 일정 삭제", isPresented: $showRecurrenceScopeForDelete, titleVisibility: .visible) {
            Button("이 일정만") { deleteWithScope(.thisOnly) }
            Button("이 일정 및 향후 일정") { deleteWithScope(.thisAndFuture) }
            Button("모든 일정", role: .destructive) { deleteWithScope(.all) }
            Button("취소", role: .cancel) { }
        } message: {
            Text("어떤 일정을 삭제하시겠습니까?")
        }
    }

    // MARK: - Subviews

    private func colorButton(for color: String) -> some View {
        let isSelected = AppColors.baseColorName(from: selectedColorName) == color
        return Button(action: {
            selectedColorName = "\(color)-4"
            selectedBaseColor = color
        }) {
            ZStack {
                Circle()
                    .fill(AppColors.color(for: "\(color)-4"))
                    .frame(width: 28, height: 28)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.contrastingTextColor(for: AppColors.color(for: "\(color)-4")))
                }
            }
            .overlay(
                Circle().stroke(
                    isSelected ? borderColor() : Color.clear,
                    lineWidth: isSelected ? 2.5 : 0
                )
            )
        }
        .buttonStyle(.borderless)
        .help("\(color) 색상")
        .onLongPressGesture {
            selectedBaseColor = color
            showColorVariationPicker = true
        }
    }

    private func menuButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            menuLabel(text: title)
        }
        .buttonStyle(.borderless)
    }

    private func menuLabel(text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textPrimary)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 9))
                .foregroundColor(AppColors.textFieldPlaceholder)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppColors.textFieldBackground)
        .cornerRadius(5)
    }

    // MARK: - Computed Properties

    private var dateContextString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        if let dateObj = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: date)
        }() {
            return formatter.string(from: dateObj)
        }
        return date
    }

    private var dynamicHeight: CGFloat {
        var h: CGFloat = 420
        if isPeriodEventEditing { h += 80 }
        if editStartDate > editEndDate && isPeriodEventEditing { h += 24 }
        return h
    }

    private var recurrenceDisplayText: String {
        if let info = selectedRecurrence {
            return info.displayString
        }
        return "안 함"
    }

    private func isRecurrenceEqual(_ a: RecurrenceInfo?, _ b: RecurrenceInfo?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case (let a?, let b?): return a == b
        default: return false
        }
    }

    // MARK: - Form Row Helper

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 72, alignment: .trailing)
            content()
            Spacer()
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        let scheduledTime: String? = hasTime ? formatTime(selectedTime) : nil
        let reminderMinutesBefore: Int? = hasReminder ? reminderMinutes : nil

        if isPeriodEventEditing {
            guard editStartDate <= editEndDate else {
                toastMessage = "시작일은 종료일보다 이전이어야 합니다."
                showToast = true
                return
            }
            viewModel.updatePeriodTodo(
                original: originalTodo,
                updatedText: editedText,
                updatedColor: selectedColorName,
                startDate: editStartDate,
                endDate: editEndDate
            )
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: date) {
                viewModel.updateTodo(original: originalTodo, text: editedText, colorName: selectedColorName, date: date)
            }
        }
        toastMessage = "일정이 수정되었습니다."
        showToast = true
        isPresented = false
    }

    private func saveWithScope(_ scope: RecurrenceEditScope) {
        let scheduledTime: String? = hasTime ? formatTime(selectedTime) : nil
        let reminderMinutesBefore: Int? = hasReminder ? reminderMinutes : nil

        let updated = TodoItem(
            text: editedText,
            isRepeating: selectedRecurrence != nil,
            date: originalTodo.date,
            colorName: selectedColorName,
            scheduledTime: scheduledTime,
            reminderMinutesBefore: reminderMinutesBefore,
            recurrenceInfo: selectedRecurrence
        )

        let effectiveDate = occurrenceDate ?? formatDate(date)
        viewModel.updateRecurringTodo(
            original: originalTodo,
            updated: updated,
            occurrenceDate: effectiveDate,
            scope: scope
        )
        toastMessage = "반복 일정이 수정되었습니다."
        showToast = true
        isPresented = false
    }

    private func deleteWithScope(_ scope: RecurrenceEditScope) {
        let effectiveDate = occurrenceDate ?? formatDate(date)
        viewModel.deleteRecurringTodo(
            originalTodo,
            occurrenceDate: effectiveDate,
            scope: scope
        )
        toastMessage = "반복 일정이 삭제되었습니다."
        showToast = true
        isPresented = false
    }

    private func performDelete() {
        viewModel.deleteTodo(todo: originalTodo)
        toastMessage = "일정이 삭제되었습니다."
        showToast = true
        isPresented = false
    }

    private func borderColor() -> Color {
        ThemeManager.isDarkMode ? Color.white : Color(hex: "#0F0F0F")
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func formatDate(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str) ?? Date()
    }
}
