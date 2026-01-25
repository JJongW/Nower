//
//  AddEventView.swift
//  Nower
//
//  Created by 신종원 on 3/22/25.
//  Updated for macOS HIG compliance on 2026/01/25.
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
    @State private var showColorVariationPicker: Bool = false
    @State private var selectedBaseColor: String = "skyblue"

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
        VStack(spacing: 0) {
            // macOS HIG: 폼은 좌우 배치가 일반적
            HStack(alignment: .top, spacing: 24) {
                // 왼쪽: 입력 필드 및 옵션
                VStack(alignment: .leading, spacing: 20) {
                    // 제목
                    Text("새 일정 추가")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.bottom, 4)
                    
                    // 할 일 입력 필드
                    VStack(alignment: .leading, spacing: 8) {
                        Text("할 일")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("", text: $eventText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.textFieldBackground)
                            .cornerRadius(6)
                            .frame(minHeight: 32) // macOS HIG: 최소 32pt 높이
                    }
                    
                    // 색상 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("색상")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 10) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button(action: {
                                    selectedColor = "\(color)-4"
                                    selectedBaseColor = color
                                }) {
                                    Circle()
                                        .fill(AppColors.color(for: "\(color)-4"))
                                        .frame(width: 36, height: 36) // macOS HIG: 최소 44pt 클릭 타겟에 가깝게
                                        .overlay(
                                            Circle().stroke(
                                                AppColors.baseColorName(from: selectedColor) == color ? borderColor() : Color.clear,
                                                lineWidth: AppColors.baseColorName(from: selectedColor) == color ? 3 : 0
                                            )
                                        )
                                }
                                .buttonStyle(.borderless)
                                .help("\(color) 색상 선택")
                                .onLongPressGesture {
                                    selectedBaseColor = color
                                    showColorVariationPicker = true
                                }
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
                    
                    // 일정 타입 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("타입")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 8) {
                            ForEach(EventType.allCases, id: \.self) { type in
                                Button(action: {
                                    viewModel.selectedEventType = type
                                    selectedDates = []
                                }) {
                                    Text(type.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(viewModel.selectedEventType == type ? AppColors.buttonTextColor : AppColors.textPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .frame(minHeight: 28) // macOS HIG: 최소 높이
                                        .background(viewModel.selectedEventType == type ? AppColors.buttonBackground : AppColors.buttonSecondaryBackground)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    
                    // 반복 옵션 (반복 타입일 때만 표시)
                    if viewModel.selectedEventType == .repeatable {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("반복 옵션")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                            
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
                                            .frame(minHeight: 28)
                                            .background(repeatOption == option ? AppColors.buttonBackground : AppColors.buttonSecondaryBackground)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                }
                .frame(width: 320) // 고정 너비로 일관성 유지
                
                // 오른쪽: 날짜 선택 (조건부 표시)
                if shouldShowDatePicker {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(datePickerTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        datePickerView
                            .frame(width: 280) // macOS 네이티브 DatePicker 크기
                    }
                }
            }
            .padding(24)
            
            Divider()
            
            // macOS HIG: 버튼은 오른쪽 하단에 배치 (취소 왼쪽, 확인 오른쪽)
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
            }
            .padding(20)
        }
        .frame(width: shouldShowDatePicker ? 640 : 380, height: shouldShowDatePicker ? 500 : 400)
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
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowDatePicker: Bool {
        viewModel.selectedEventType == .normal || 
        viewModel.selectedEventType == .repeatable || 
        viewModel.selectedEventType == .multiple
    }
    
    private var datePickerTitle: String {
        switch viewModel.selectedEventType {
        case .normal: return "날짜"
        case .repeatable: return "반복 시작 날짜"
        case .multiple: return "날짜 선택"
        case .duration: return ""
        }
    }
    
    @ViewBuilder
    private var datePickerView: some View {
        switch viewModel.selectedEventType {
        case .normal, .repeatable:
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .accentColor(AppColors.textHighlighted)
                .labelsHidden()
                
        case .multiple:
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(AppColors.textHighlighted)
                    .labelsHidden()
                    .onChange(of: selectedDate) { newValue in
                        selectedDates.insert(newValue)
                    }
                
                if !selectedDates.isEmpty {
                    Text("선택된 날짜: \(selectedDates.count)개")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                }
            }
            
        case .duration:
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("시작일")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("종료일")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                if startDate > endDate {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.coralred)
                            .font(.system(size: 12))
                        Text("시작일은 종료일보다 이전이어야 합니다")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.coralred)
                    }
                }
            }
        }
    }
    
    /// 선택된 색상에 맞는 테두리 색상 (다크모드/라이트모드에 따라)
    private func borderColor() -> Color {
        ThemeManager.isDarkMode ? Color.white : Color(hex: "#0F0F0F")
    }

    // MARK: - Actions
    
    private func saveEvent() {
        guard !eventText.isEmpty else { return }
        
        switch viewModel.selectedEventType {
        case .normal:
            viewModel.selectedDate = selectedDate
            viewModel.todoText = eventText
            viewModel.selectedColorName = selectedColor
            viewModel.isRepeating = false
            viewModel.addTodo()
            
        case .repeatable:
            viewModel.selectedDate = selectedDate
            viewModel.todoText = eventText
            viewModel.selectedColorName = selectedColor
            viewModel.isRepeating = true
            viewModel.addTodo()
            
        case .multiple:
            for date in selectedDates {
                viewModel.selectedDate = date
                viewModel.todoText = eventText
                viewModel.selectedColorName = selectedColor
                viewModel.isRepeating = false
                viewModel.addTodo()
            }
            
        case .duration:
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
