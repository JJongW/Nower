//
//  ContentGridView.swift
//  Nower
//
//  Created by 신종원 on 3/16/25.
//

import Foundation
import SwiftUI

struct CalendarGridView: View {
    @EnvironmentObject var viewModel: CalendarViewModel // ✅ 전역 모델 사용

    let maxTodosToShow = 3
    @State private var selectedDate: String? = nil
    @State private var selectedTodo: TodoItem? = nil
    @State private var isShowingAlert: Bool = false

    func getToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // ✅ 날짜 포맷을 년-월-일로 변경
        return formatter.string(from: Date())
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 7), spacing: 10) { // ✅ 좌측 정렬 적용
                ForEach(viewModel.dates, id: \..id) { day in
                    VStack(alignment: .leading, spacing: 4) { // ✅ 날짜와 투두를 하나의 VStack에 배치
                        Text(formatDisplayDate(day.date))
                            .foregroundColor(day.date == getToday() ? AppColors.textHighlighted : AppColors.textColor1)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                            .onTapGesture {
                                selectedDate = day.date // ✅ 날짜 선택
                            }

                        VStack(alignment: .leading, spacing: 2) { // ✅ 할 일 목록을 내부에 배치
                            if let matchedDay = viewModel.dates.first(where: { $0.date == day.date }) {
                                ForEach(matchedDay.todos.prefix(maxTodosToShow), id: \..id) { todo in
                                    todoView(todo, for: matchedDay.date)
                                }

                                // Show more indicator if todos exceed limit
                                if matchedDay.todos.count > maxTodosToShow {
                                    Text("Add more \(matchedDay.todos.count - maxTodosToShow)")
                                        .font(.caption)
                                        .foregroundColor(AppColors.textColor1)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .frame(minWidth: 120, maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .alert(isPresented: $isShowingAlert) {
            deleteAlert()
        }
    }

    func formatDisplayDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "d" // ✅ 화면에 보이는 형식은 '일'만 표시
            return formatter.string(from: date)
        }
        return dateString
    }

    @ViewBuilder
    private func todoView(_ todo: TodoItem, for date: String) -> some View {
        Text(todo.text)
            .font(.caption)
            .foregroundColor(AppColors.textColor1)
            .padding(.horizontal, 4)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                selectedTodo = todo
                selectedDate = date
                isShowingAlert = true
                print("✅ Selected Todo: \(todo.text) for Date: \(date)")
            }
    }

    private func deleteAlert() -> Alert {
        Alert(
            title: Text("삭제하시겠습니까?"),
            primaryButton: .destructive(Text("삭제")) {
                if let date = selectedDate, let todo = selectedTodo {
                    print("🗑 Deleting Todo: \(todo.text) for Date: \(date)")
                    viewModel.deleteTodo(for: date, todo: todo)
                }
            },
            secondaryButton: .cancel()
        )
    }
}
