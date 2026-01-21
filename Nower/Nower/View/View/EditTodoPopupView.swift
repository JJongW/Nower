//
//  EditTodoPopupView.swift
//  Nower
//
//  Created by 신종원 on 3/29/25.
//

import SwiftUI

struct EditTodoPopupView: View {
    let originalTodo: TodoItem
    let date: String
    @Binding var isPresented: Bool

    @EnvironmentObject var viewModel: CalendarViewModel

    @State private var editedText: String
    @State private var selectedColorName: String
    @State private var editStartDate: Date // 기간별 일정 수정용
    @State private var editEndDate: Date   // 기간별 일정 수정용
    @State private var isPeriodEventEditing: Bool // 기간별 일정 수정 모드
    @Binding var showToast: Bool
    @Binding var toastMessage: String

    init(todo: TodoItem, date: String, isPresented: Binding<Bool>, showToast: Binding<Bool>, toastMessage: Binding<String>) {
        self.originalTodo = todo
        self.date = date
        self._isPresented = isPresented
        self._showToast = showToast
        self._toastMessage = toastMessage
        _editedText = State(initialValue: todo.text)
        _selectedColorName = State(initialValue: todo.colorName)
        _isPeriodEventEditing = State(initialValue: todo.isPeriodEvent)
        // 기간별 일정인 경우 시작일과 종료일 초기화
        _editStartDate = State(initialValue: todo.startDateObject ?? Date())
        _editEndDate = State(initialValue: todo.endDateObject ?? Date())
    }


    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("일정 편집")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 8)

                TextField("일정 내용", text: $editedText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.textFieldBackground)
                    .cornerRadius(8)
                    .foregroundColor(AppColors.textPrimary)
                    .font(.system(size: 14))

            // 색상 선택 바
            HStack(spacing: 12) {
                ForEach(["skyblue", "peach", "lavender", "mintgreen", "coralred"], id: \.self) { name in
                    Circle()
                        .fill(AppColors.color(for: name))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(
                                selectedColorName == name ? AppColors.textPrimary : Color.clear,
                                lineWidth: selectedColorName == name ? 3 : 0
                            )
                        )
                        .onTapGesture {
                            selectedColorName = name
                        }
                }
            }
            .padding(.top, 8)
            
            // 기간별 일정 수정 UI
            if isPeriodEventEditing {
                VStack(spacing: 16) {
                    Text("기간 수정")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("시작일")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            DatePicker("", selection: $editStartDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("종료일")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            DatePicker("", selection: $editEndDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                    }
                    
                    if editStartDate > editEndDate {
                        Text("⚠️ 시작일은 종료일보다 이전이어야 합니다")
                            .font(.caption)
                            .foregroundColor(AppColors.coralred)
                    }
                }
                .padding()
                .background(AppColors.textFieldBackground)
                .cornerRadius(12)
            }

            HStack(spacing: 20) {
                Button(action: {
                    viewModel.deleteTodo(todo: originalTodo)
                    toastMessage = "🗑 일정이 삭제되었습니다."
                    showToast = true
                    isPresented = false
                }) {
                    Text("삭제")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.coralred)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppColors.buttonSecondaryBackground)
                .buttonStyle(.borderless)
                .cornerRadius(8)

                if originalTodo.isRepeating {
                    Button(action: {
                        viewModel.deleteTodo(todo: originalTodo)
                        toastMessage = "🗑 반복 일정이 삭제되었습니다."
                        showToast = true
                        isPresented = false
                    }) {
                        Text("반복 전체 삭제")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.coralred)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.buttonSecondaryBackground)
                    .buttonStyle(.borderless)
                    .cornerRadius(8)
                }

                Spacer()

                Button("저장") {
                    // 기간별 일정인 경우와 단일 일정인 경우를 구분하여 처리
                    if isPeriodEventEditing {
                        // 기간별 일정 수정
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
                        toastMessage = "✅ 일정이 수정되었습니다."
                        showToast = true
                    } else {
                        // 단일 일정 수정
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        if let date = formatter.date(from: date) {
                            viewModel.updateTodo(original: originalTodo, text: editedText, colorName: selectedColorName, date: date)
                            toastMessage = "✅ 일정이 수정되었습니다."
                            showToast = true
                        } else {
                            toastMessage = "❌ 날짜 형식 오류"
                            showToast = true
                        }
                    }
                    isPresented = false
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.buttonTextColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .buttonStyle(.borderless)
                .background(AppColors.buttonBackground)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            }
        }
        .padding()
        .background(AppColors.popupBackground)
        .cornerRadius(12)
        .frame(width: 500) // 고정 너비
        .frame(minHeight: 400, maxHeight: 700) // 최소/최대 높이 설정
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10) // 그림자 추가
    }

    func formatDate(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str) ?? Date()
    }
}
