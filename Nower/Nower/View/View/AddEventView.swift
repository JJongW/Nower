//
//  AddEventView.swift
//  Nower
//
//  Created by 신종원 on 3/22/25.
//
import Foundation
import SwiftUI

struct AddEventView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var eventText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedDates: Set<Date> = []
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @Binding var selectedColor: String
    @State private var repeatOption: RepeatOption = .none
    @Binding var isPopupVisible: Bool

    let colorOptions: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]
    
    // 초기 날짜를 설정할 수 있는 초기화자
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
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                TextField("", text: $eventText)
                    .placeholder(when: eventText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                           Text("할 일을 입력하세요")
                               .foregroundColor(AppColors.textFieldPlaceholder)
                               .font(.system(size: 16, weight: .medium))
                               .padding(.leading, 8)
                       }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppColors.textFieldBackground)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .textFieldStyle(.plain)

                HStack(spacing: 12) {
                    ForEach(colorOptions, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(AppColors.color(for: color))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(
                                        selectedColor == color ? AppColors.textPrimary : Color.clear,
                                        lineWidth: selectedColor == color ? 3 : 0
                                    )
                                )
                        }
                        .buttonStyle(.borderless)
                    }
                }

                HStack {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Button(action: {
                            viewModel.selectedEventType = type
                            selectedDates = []
                        }) {
                            Text(type.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedEventType == type ? AppColors.textHighlighted : AppColors.buttonSecondaryBackground)
                                .foregroundColor(viewModel.selectedEventType == type ? AppColors.buttonTextColor : AppColors.textPrimary)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                if viewModel.selectedEventType == .normal {
                    VStack(alignment: .leading) {
                        Text("날짜 선택")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .accentColor(AppColors.textHighlighted)
                    }
                }

                if viewModel.selectedEventType == .duration {
                    VStack(spacing: 16) {
                        Text("기간별 일정")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("시작일과 종료일을 선택하세요")
                            .font(.caption)
                            .foregroundColor(AppColors.textFieldPlaceholder)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("시작일")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("종료일")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                        }
                        
                        if startDate > endDate {
                            Text("⚠️ 시작일은 종료일보다 이전이어야 합니다")
                                .font(.caption)
                                .foregroundColor(AppColors.coralred)
                        }
                    }
                    .padding()
                    .background(AppColors.textFieldBackground)
                    .cornerRadius(12)
                    .accentColor(AppColors.textHighlighted)
                }

                if viewModel.selectedEventType == .repeatable {
                    VStack(alignment: .center) {
                        Text("반복 시작 날짜")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .accentColor(AppColors.primaryPink)

                        HStack(spacing: 8) {
                            ForEach(RepeatOption.allCases, id: \.self) { option in
                                Button(action: {
                                    repeatOption = option
                                }) {
                                    Text(option.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(repeatOption == option ? AppColors.buttonTextColor : AppColors.textPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(repeatOption == option ? AppColors.buttonBackground : AppColors.buttonSecondaryBackground)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                    }
                }

                if viewModel.selectedEventType == .multiple {
                    VStack(alignment: .leading) {
                        Text("여러 날짜 설정")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                            .accentColor(AppColors.primaryPink)
                            .onChange(of: selectedDate) { newValue in
                                selectedDates.insert(newValue)
                            }

                        Text("선택된 날짜 수: \(selectedDates.count)")
                            .font(.caption)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("취소") {
                    viewModel.isAddingEvent = false
                    isPopupVisible = false
                }
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .foregroundColor(AppColors.textPrimary)
                .background(AppColors.buttonSecondaryBackground)
                .buttonStyle(.borderless)
                .cornerRadius(8)

                Button("저장") {
                    saveEvent()
                    viewModel.isAddingEvent = false
                    isPopupVisible = false
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.buttonTextColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .buttonStyle(.borderless)
                .background(AppColors.buttonBackground)
                .cornerRadius(8)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: 500) // 기간별 일정 UI를 위해 너비 증가
        .frame(maxHeight: 600) // 최대 높이 제한
        .padding()
        .background(AppColors.popupBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5) // 그림자 추가로 팝업이 더 명확하게 보이도록
        .onAppear {
            // selectedColor가 빈 문자열이면 기본값 설정
            if selectedColor.isEmpty {
                selectedColor = "skyblue"
            }
            // viewModel의 selectedDate도 초기 날짜로 설정
            viewModel.selectedDate = selectedDate
        }
    }

    private func saveEvent() {
        guard !eventText.isEmpty else { return }
        
        switch viewModel.selectedEventType {
        case .normal:
            // 단일 날짜 일정 추가
            viewModel.selectedDate = selectedDate
            viewModel.todoText = eventText
            viewModel.selectedColorName = selectedColor
            viewModel.isRepeating = false
            viewModel.addTodo()
            
        case .repeatable:
            // 반복 일정 추가 (현재는 단일 날짜로 저장)
            viewModel.selectedDate = selectedDate
            viewModel.todoText = eventText
            viewModel.selectedColorName = selectedColor
            viewModel.isRepeating = true
            viewModel.addTodo()
            
        case .multiple:
            // 여러 날짜에 각각 일정 추가
            for date in selectedDates {
                viewModel.selectedDate = date
                viewModel.todoText = eventText
                viewModel.selectedColorName = selectedColor
                viewModel.isRepeating = false
                viewModel.addTodo()
            }
            
        case .duration:
            // 기간별 일정 추가 (iOS 버전과 동일하게 하나의 TodoItem으로 저장)
            guard startDate <= endDate else { return }
            viewModel.selectedStartDate = startDate
            viewModel.selectedEndDate = endDate
            viewModel.todoText = eventText
            viewModel.selectedColorName = selectedColor
            viewModel.isRepeating = false
            viewModel.addPeriodTodo()
        }
    }

}

// 반복 옵션 정의
enum RepeatOption: String, CaseIterable {
    case none = "반복 없음"
    case daily = "매일"
    case weekly = "매주"
    case monthly = "매월"
    case yearly = "매년"
}

// 이벤트 타입 정의
enum EventType: String, CaseIterable {
    case normal = "일반"
    case duration = "기간"
    case repeatable = "반복"
    case multiple = "다중"
}
