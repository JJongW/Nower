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
    @Binding var selectedColor: String
    @State private var repeatOption: RepeatOption = .none
    @Binding var isPopupVisible: Bool

    let colorOptions: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 20) {
                TextField("할 일을 입력하세요", text: $eventText)
                    .padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .background(AppColors.popupBackground)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textWhite)
                    .textFieldStyle(.plain)

                // 원하는 색 선택 바
                HStack {
                    ForEach(colorOptions, id: \..self) { color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(AppColors.color(for: "\(color)"))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.textWhite, lineWidth: selectedColor == color.description ? 1 : 0)
                                )
                        }
                        .buttonStyle(.borderless)
                    }
                }

                // 일정 유형 선택 바
                HStack {
                    ForEach(EventType.allCases, id: \..self) { type in
                        Button(action: {
                            viewModel.selectedEventType = type
                            if type == .normal || type == .repeatable {
                                selectedDates = []
                            }
                        }) {
                            Text(type.rawValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.selectedEventType == type ? AppColors.textHighlighted : AppColors.black)
                                .foregroundColor(viewModel.selectedEventType == type ? .white : .white)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                // 날짜 선택 방식에 따라 다르게 표시
                if viewModel.selectedEventType == .normal {
                    VStack(alignment: .leading) {
                        Text("날짜 선택")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .accentColor(AppColors.textHighlighted)

                    }
                }

                if viewModel.selectedEventType == .duration {
                    VStack(spacing: 10) {
                        Text("기간 선택: 시작일 → 종료일 순서로 선택하세요")
                            .font(.caption)
                            .foregroundColor(.gray)
                        DatePicker("시작 날짜", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                        DatePicker("종료 날짜", selection: Binding(
                            get: { selectedDates.max() ?? selectedDate },
                            set: { selectedDates.insert($0) }
                        ), displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                    .accentColor(AppColors.textHighlighted)
                }

                if viewModel.selectedEventType == .repeatable {
                    VStack(alignment: .leading) {
                        Text("반복 시작 날짜")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .accentColor(AppColors.primaryPink)
                    }
                    Picker("반복 설정", selection: $repeatOption) {
                        ForEach(RepeatOption.allCases, id: \..self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }

                if viewModel.selectedEventType == .multiple {
                    VStack(alignment: .leading) {
                        Text("여러 날짜 설정")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                            .accentColor(AppColors.primaryPink)
                            .onChange(of: selectedDate) { newValue in
                                selectedDates.insert(newValue)
                            }

                        Text("선택된 날짜 수: \(selectedDates)")
                            .font(.caption)
                    }
                }
            }

            HStack {
                Button("취소") {
                    viewModel.isAddingEvent = false
                    isPopupVisible = false
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundColor(AppColors.textWhite)
                .background(AppColors.black)
                .buttonStyle(.borderless)
                .cornerRadius(16)

                Button("저장") {
                    switch viewModel.selectedEventType {
                    case .normal:
                        viewModel.addTodo(for: selectedDate, todo: eventText, repeatOption: .none, colorName: selectedColor)
                    case .repeatable:
                        viewModel.addTodo(for: selectedDate, todo: eventText, repeatOption: repeatOption, colorName: selectedColor)
                    case .multiple:
                        for date in selectedDates {
                            viewModel.addTodo(for: date, todo: eventText, repeatOption: .none, colorName: selectedColor)
                        }
                    case .duration:
                        if let start = selectedDates.min(), let end = selectedDates.max() {
                            let calendar = Calendar.current
                            var date = start
                            while date <= end {
                                viewModel.addTodo(for: date, todo: eventText, repeatOption: .none, colorName: selectedColor)
                                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                            }
                        }
                    }
                    viewModel.isAddingEvent = false
                    isPopupVisible = false
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .buttonStyle(.borderless)
                .background(AppColors.textHighlighted)
                .cornerRadius(16)
            }
            Spacer()
        }
        .frame(height: 400)
        .frame(maxWidth: 400)
        .padding()
        .background(AppColors.popupBackground)
        .cornerRadius(12)
    }
}

enum RepeatOption: String, CaseIterable {
    case none = "반복 없음"
    case daily = "매일"
    case weekly = "매주"
    case monthly = "매월"
    case yearly = "매년"
}

enum EventType: String, CaseIterable {
    case normal = "일반"
    case duration = "기간"
    case repeatable = "반복"
    case multiple = "다중"
}
