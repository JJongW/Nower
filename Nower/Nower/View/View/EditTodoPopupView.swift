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
    }


    var body: some View {
        VStack(spacing: 20) {
            Text("일정 편집")
                .font(.headline)
                .foregroundColor(AppColors.textColor1)

            TextField("일정 내용", text: $editedText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // 색상 선택 바
            HStack {
                ForEach(["skyblue", "peach", "lavender", "mintgreen", "coralred"], id: \.self) { name in
                    Circle()
                        .fill(AppColors.color(for: name))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: selectedColorName == name ? 2 : 0)
                        )
                        .onTapGesture {
                            selectedColorName = name
                        }
                }
            }
            .padding(.top, 8)

            HStack(spacing: 20) {
                Button(action: {
                    viewModel.deleteTodo(todo: originalTodo)
                    toastMessage = "🗑 일정이 삭제되었습니다."
                    showToast = true
                    isPresented = false
                }) {
                    Text("삭제")
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .buttonStyle(.borderless)
                .cornerRadius(16)

                if originalTodo.isRepeating {
                    Button(action: {
                        viewModel.deleteTodo(todo: originalTodo)
                        toastMessage = "🗑 반복 일정이 삭제되었습니다."
                        showToast = true
                        isPresented = false
                    }) {
                        Text("반복 전체 삭제")
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .buttonStyle(.borderless)
                    .frame(minWidth: 30)
                    .cornerRadius(16)
                }

                Spacer()

                Button("저장") {
                    isPresented = false
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .buttonStyle(.borderless)
                .background(AppColors.primaryPink)
                .cornerRadius(16)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(AppColors.popupBackground)
        .cornerRadius(12)
        .frame(maxWidth: 400)
    }

    func formatDate(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str) ?? Date()
    }
}
