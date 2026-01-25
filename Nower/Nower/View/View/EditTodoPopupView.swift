//
//  EditTodoPopupView.swift
//  Nower
//
//  Created by 신종원 on 3/29/25.
//  Updated for macOS HIG compliance on 2026/01/25.
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

    init(todo: TodoItem, date: String, isPresented: Binding<Bool>, showToast: Binding<Bool>, toastMessage: Binding<String>) {
        self.originalTodo = todo
        self.date = date
        self._isPresented = isPresented
        self._showToast = showToast
        self._toastMessage = toastMessage
        _editedText = State(initialValue: todo.text)
        _selectedColorName = State(initialValue: todo.colorName)
        _isPeriodEventEditing = State(initialValue: todo.isPeriodEvent)
        _editStartDate = State(initialValue: todo.startDateObject ?? Date())
        _editEndDate = State(initialValue: todo.endDateObject ?? Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // macOS HIG: 폼은 좌우 배치
            HStack(alignment: .top, spacing: 24) {
                // 왼쪽: 입력 필드 및 옵션
                VStack(alignment: .leading, spacing: 20) {
                    // 제목
                    Text("일정 편집")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.bottom, 4)
                    
                    // 일정 내용 입력 필드
                    VStack(alignment: .leading, spacing: 8) {
                        Text("할 일")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("일정 내용", text: $editedText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.textFieldBackground)
                            .cornerRadius(6)
                            .frame(minHeight: 32)
                    }
                    
                    // 색상 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("색상")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 10) {
                            ForEach(["skyblue", "peach", "lavender", "mintgreen", "coralred"], id: \.self) { name in
                                Button(action: {
                                    selectedColorName = "\(name)-4"
                                    selectedBaseColor = name
                                }) {
                                    Circle()
                                        .fill(AppColors.color(for: "\(name)-4"))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle().stroke(
                                                AppColors.baseColorName(from: selectedColorName) == name ? borderColor() : Color.clear,
                                                lineWidth: AppColors.baseColorName(from: selectedColorName) == name ? 3 : 0
                                            )
                                        )
                                }
                                .buttonStyle(.borderless)
                                .help("\(name) 색상 선택")
                                .onLongPressGesture {
                                    selectedBaseColor = name
                                    showColorVariationPicker = true
                                }
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
                    
                    // 기간별 일정 수정 UI
                    if isPeriodEventEditing {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("기간")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("시작일")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textPrimary)
                                    DatePicker("", selection: $editStartDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("종료일")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textPrimary)
                                    DatePicker("", selection: $editEndDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                }
                                
                                if editStartDate > editEndDate {
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
                            .padding(12)
                            .background(AppColors.textFieldBackground)
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(width: 320)
            }
            .padding(24)
            
            Divider()
            
            // macOS HIG: 버튼 배치 (삭제 왼쪽, 취소/저장 오른쪽)
            HStack {
                // 삭제 버튼 (왼쪽)
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("삭제")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.bordered)
                .foregroundColor(AppColors.coralred)
                .alert("일정 삭제", isPresented: $showDeleteConfirmation) {
                    Button("취소", role: .cancel) { }
                    Button("삭제", role: .destructive) {
                        performDelete()
                    }
                } message: {
                    Text("'\(originalTodo.text)'을(를) 삭제하시겠습니까?")
                }
                
                if originalTodo.isRepeating {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("반복 전체 삭제")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(AppColors.coralred)
                }
                
                Spacer()
                
                // 취소/저장 버튼 (오른쪽)
                Button("취소") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)
                
                Button("저장") {
                    saveChanges()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .frame(width: 380, height: isPeriodEventEditing ? 500 : 400)
        .background(AppColors.popupBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            selectedBaseColor = AppColors.baseColorName(from: selectedColorName)
            if AppColors.toneNumber(from: selectedColorName) == nil {
                selectedColorName = "\(selectedColorName)-4"
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        if isPeriodEventEditing {
            guard editStartDate <= editEndDate else {
                toastMessage = "⚠️ 시작일은 종료일보다 이전이어야 합니다."
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
            toastMessage = "일정이 수정되었습니다."
            showToast = true
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: date) {
                viewModel.updateTodo(original: originalTodo, text: editedText, colorName: selectedColorName, date: date)
                toastMessage = "일정이 수정되었습니다."
                showToast = true
            } else {
                toastMessage = "❌ 날짜 형식 오류"
                showToast = true
            }
        }
        isPresented = false
    }
    
    private func performDelete() {
        viewModel.deleteTodo(todo: originalTodo)
        toastMessage = "일정이 삭제되었습니다."
        showToast = true
        isPresented = false
    }
    
    /// 선택된 색상에 맞는 테두리 색상 (다크모드/라이트모드에 따라)
    private func borderColor() -> Color {
        ThemeManager.isDarkMode ? Color.white : Color(hex: "#0F0F0F")
    }

    func formatDate(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str) ?? Date()
    }
}
