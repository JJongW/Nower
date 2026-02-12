//
//  AddEventView.swift
//  Nower
//
//  Created by 신종원 on 3/22/25.
//  Redesigned for macOS Apple Calendar-style UX on 2026/02/10.
//
import Foundation
import SwiftUI

struct AddEventView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var eventText: String = ""
    @State private var selectedDate: Date = Date()
    @Binding var selectedColor: String
    @Binding var isPopupVisible: Bool
    @State private var showColorVariationPicker: Bool = false
    @State private var selectedBaseColor: String = "skyblue"

    // 기간 모드
    @State private var isPeriodMode: Bool = false
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()

    // 시간 설정 (nil = 하루 종일)
    @State private var hasTime: Bool = false
    @State private var selectedTime: Date = Date()

    // 알림 설정 (nil = 없음)
    @State private var hasReminder: Bool = false
    @State private var reminderMinutes: Int = 0

    // 반복 설정
    @State private var selectedRecurrence: RecurrenceInfo? = nil
    @State private var showCustomRecurrence: Bool = false

    let colorOptions: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]
    let reminderOptions: [(label: String, minutes: Int)] = [
        ("정시", 0),
        ("5분 전", 5),
        ("10분 전", 10),
        ("30분 전", 30),
        ("1시간 전", 60),
        ("하루 전", 1440)
    ]

    let recurrencePresets: [(label: String, info: RecurrenceInfo?)] = [
        ("안 함", nil),
        ("매일", RecurrenceInfo(frequency: "daily")),
        ("매주", RecurrenceInfo(frequency: "weekly")),
        ("평일 (월~금)", RecurrenceInfo(frequency: "weekly", daysOfWeek: [2, 3, 4, 5, 6])),
        ("매월", RecurrenceInfo(frequency: "monthly")),
        ("매년", RecurrenceInfo(frequency: "yearly"))
    ]

    private static let placeholders = ["점심 약속", "팀 미팅", "치과 예약", "운동", "생일 파티"]

    @State private var placeholderText: String = AddEventView.placeholders.randomElement() ?? "일정 이름"

    init(initialDate: Date? = nil, selectedColor: Binding<String>, isPopupVisible: Binding<Bool>) {
        self._selectedColor = selectedColor
        self._isPopupVisible = isPopupVisible
        if let date = initialDate {
            self._selectedDate = State(initialValue: date)
            self._startDate = State(initialValue: date)
            self._endDate = State(initialValue: date)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더 + 날짜 컨텍스트
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("새 일정")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
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

            // 컨텐츠
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 제목
                    formRow(label: "제목") {
                        TextField(placeholderText, text: $eventText)
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
                                selectedTone: AppColors.toneNumber(from: selectedColor),
                                onColorSelected: { colorName in
                                    selectedColor = colorName
                                    showColorVariationPicker = false
                                }
                            )
                        }
                    }

                    Divider()
                        .padding(.horizontal, -4)

                    // 날짜 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        formRow(label: "기간 일정") {
                            Toggle("", isOn: $isPeriodMode)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .onChange(of: isPeriodMode) { newValue in
                                    if newValue { selectedRecurrence = nil }
                                }
                        }

                        if isPeriodMode {
                            formRow(label: "시작일") {
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            formRow(label: "종료일") {
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                            if startDate > endDate {
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
                        } else {
                            formRow(label: "날짜") {
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                        }
                    }

                    Divider()
                        .padding(.horizontal, -4)

                    // 시간 — Apple Calendar 스타일: 메뉴로 통일
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

                    // 반복
                    formRow(label: "반복") {
                        if isPeriodMode {
                            Text("기간 일정은 반복 불가")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textFieldPlaceholder)
                        } else {
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

                    // 알림 — Apple Calendar 스타일: 메뉴로 통일
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

            // 하단 버튼 바 (macOS HIG)
            HStack {
                Spacer()
                Button("취소") {
                    viewModel.isAddingEvent = false
                    isPopupVisible = false
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)

                Button("저장") {
                    saveEvent()
                    viewModel.isAddingEvent = false
                    isPopupVisible = false
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(eventText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 420, height: dynamicHeight)
        .background(AppColors.popupBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            if selectedColor.isEmpty {
                selectedColor = "skyblue-4"
            } else if AppColors.toneNumber(from: selectedColor) == nil {
                selectedColor = "\(selectedColor)-4"
            }
            selectedBaseColor = AppColors.baseColorName(from: selectedColor)
            viewModel.selectedDate = selectedDate
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
    }

    // MARK: - Subviews

    private func colorButton(for color: String) -> some View {
        let isSelected = AppColors.baseColorName(from: selectedColor) == color
        return Button(action: {
            selectedColor = "\(color)-4"
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
        return formatter.string(from: selectedDate)
    }

    private var dynamicHeight: CGFloat {
        var height: CGFloat = 420
        if isPeriodMode { height += 40 }
        if startDate > endDate && isPeriodMode { height += 24 }
        return height
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

    private func saveEvent() {
        let trimmedText = eventText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return }

        let scheduledTime: String? = hasTime ? formatTime(selectedTime) : nil
        let reminderMinutesBefore: Int? = hasReminder ? reminderMinutes : nil

        if isPeriodMode {
            guard startDate <= endDate else { return }
            viewModel.selectedStartDate = startDate
            viewModel.selectedEndDate = endDate
            viewModel.todoText = trimmedText
            viewModel.selectedColorName = selectedColor
            viewModel.isRepeating = false
            viewModel.selectedScheduledTime = scheduledTime
            viewModel.selectedReminderMinutesBefore = reminderMinutesBefore
            viewModel.selectedRecurrenceInfo = nil
            viewModel.addPeriodTodo()
        } else {
            viewModel.selectedDate = selectedDate
            viewModel.todoText = trimmedText
            viewModel.selectedColorName = selectedColor
            viewModel.isRepeating = selectedRecurrence != nil
            viewModel.selectedScheduledTime = scheduledTime
            viewModel.selectedReminderMinutesBefore = reminderMinutesBefore
            viewModel.selectedRecurrenceInfo = selectedRecurrence
            viewModel.addTodo()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func borderColor() -> Color {
        ThemeManager.isDarkMode ? Color.white : Color(hex: "#0F0F0F")
    }
}

// MARK: - Custom Recurrence Sheet (macOS)

struct CustomRecurrenceSheet: View {
    let initialInfo: RecurrenceInfo?
    let onSave: (RecurrenceInfo) -> Void
    let onCancel: () -> Void

    @State private var frequency: String = "daily"
    @State private var interval: Int = 1
    @State private var selectedDaysOfWeek: Set<Int> = []
    @State private var dayOfMonth: Int = 1
    @State private var endCondition: EndCondition = .never
    @State private var endAfterCount: Int = 10
    @State private var endOnDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    private let frequencies = ["daily", "weekly", "monthly", "yearly"]
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    enum EndCondition: String, CaseIterable {
        case never = "안 함"
        case afterCount = "횟수 후"
        case onDate = "날짜까지"
    }

    init(initialInfo: RecurrenceInfo?, onSave: @escaping (RecurrenceInfo) -> Void, onCancel: @escaping () -> Void) {
        self.initialInfo = initialInfo
        self.onSave = onSave
        self.onCancel = onCancel

        if let info = initialInfo {
            _frequency = State(initialValue: info.frequency)
            _interval = State(initialValue: info.interval)
            if let days = info.daysOfWeek {
                _selectedDaysOfWeek = State(initialValue: Set(days))
            }
            if let day = info.dayOfMonth {
                _dayOfMonth = State(initialValue: day)
            }
            if let endDate = info.endDate {
                _endCondition = State(initialValue: .onDate)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: endDate) {
                    _endOnDate = State(initialValue: date)
                }
            } else if let count = info.endAfterCount {
                _endCondition = State(initialValue: .afterCount)
                _endAfterCount = State(initialValue: count)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("사용자 설정 반복")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                sheetRow(label: "빈도") {
                    Picker("", selection: $frequency) {
                        Text("매일").tag("daily")
                        Text("매주").tag("weekly")
                        Text("매월").tag("monthly")
                        Text("매년").tag("yearly")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
                }

                sheetRow(label: "간격") {
                    HStack(spacing: 8) {
                        Stepper(value: $interval, in: 1...99) {
                            Text("\(interval)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(width: 30, alignment: .center)
                        }
                        Text(intervalUnit)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textFieldPlaceholder)
                    }
                }

                if frequency == "weekly" {
                    sheetRow(label: "요일") {
                        HStack(spacing: 4) {
                            ForEach(1...7, id: \.self) { day in
                                Button(action: {
                                    if selectedDaysOfWeek.contains(day) {
                                        selectedDaysOfWeek.remove(day)
                                    } else {
                                        selectedDaysOfWeek.insert(day)
                                    }
                                }) {
                                    Text(weekdayLabels[day - 1])
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 32, height: 28)
                                        .foregroundColor(selectedDaysOfWeek.contains(day) ? .white : AppColors.textPrimary)
                                        .background(selectedDaysOfWeek.contains(day) ? AppColors.buttonBackground : AppColors.buttonSecondaryBackground)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }

                if frequency == "monthly" {
                    sheetRow(label: "일자") {
                        Stepper(value: $dayOfMonth, in: 1...31) {
                            Text("\(dayOfMonth)일")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }

                Divider()

                sheetRow(label: "종료") {
                    Picker("", selection: $endCondition) {
                        ForEach(EndCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()
                }

                if endCondition == .afterCount {
                    sheetRow(label: "") {
                        HStack(spacing: 8) {
                            Stepper(value: $endAfterCount, in: 1...999) {
                                Text("\(endAfterCount)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(width: 40, alignment: .center)
                            }
                            Text("회 후 종료")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textFieldPlaceholder)
                        }
                    }
                }

                if endCondition == .onDate {
                    sheetRow(label: "") {
                        DatePicker("", selection: $endOnDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textHighlighted)
                    Text(previewText)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                }
                .padding(.leading, 92)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            HStack {
                Spacer()
                Button("취소") { onCancel() }
                    .keyboardShortcut(.escape)
                    .buttonStyle(.bordered)
                Button("적용") {
                    let info = buildRecurrenceInfo()
                    onSave(info)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 420, height: dynamicSheetHeight)
        .background(AppColors.popupBackground)
    }

    private var dynamicSheetHeight: CGFloat {
        var h: CGFloat = 340
        if frequency == "weekly" { h += 44 }
        if frequency == "monthly" { h += 44 }
        if endCondition == .afterCount { h += 40 }
        if endCondition == .onDate { h += 40 }
        return h
    }

    private var intervalUnit: String {
        switch frequency {
        case "daily": return "일마다"
        case "weekly": return "주마다"
        case "monthly": return "개월마다"
        case "yearly": return "년마다"
        default: return ""
        }
    }

    private var previewText: String {
        let info = buildRecurrenceInfo()
        var text = info.displayString
        switch endCondition {
        case .never: break
        case .afterCount: text += " (\(endAfterCount)회)"
        case .onDate:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd"
            text += " (~\(formatter.string(from: endOnDate)))"
        }
        return text
    }

    private func buildRecurrenceInfo() -> RecurrenceInfo {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let endDateStr: String? = endCondition == .onDate ? formatter.string(from: endOnDate) : nil
        let endCount: Int? = endCondition == .afterCount ? endAfterCount : nil
        let days: [Int]? = frequency == "weekly" && !selectedDaysOfWeek.isEmpty ? Array(selectedDaysOfWeek) : nil
        let dom: Int? = frequency == "monthly" ? dayOfMonth : nil

        return RecurrenceInfo(
            frequency: frequency,
            interval: interval,
            endDate: endDateStr,
            endAfterCount: endCount,
            daysOfWeek: days,
            dayOfMonth: dom
        )
    }

    private func sheetRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 72, alignment: .trailing)
            content()
            Spacer()
        }
    }
}

// 이벤트 타입 정의 (하위 호환성 유지)
enum EventType: String, CaseIterable {
    case normal = "일반"
    case duration = "기간"
    case repeatable = "반복"
    case multiple = "다중"
}

// 반복 옵션 정의 (하위 호환성 유지)
enum RepeatOption: String, CaseIterable {
    case none = "반복 없음"
    case daily = "매일"
    case weekly = "매주"
    case monthly = "매월"
    case yearly = "매년"
}
