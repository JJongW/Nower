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
    @State private var showDeleteOptions = false

    func getToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(viewModel.dates, id: \..id) { day in
                    calendarCell(for: day)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .alert(isPresented: $isShowingAlert) {
            if let todo = selectedTodo, let date = selectedDate {
                return Alert(
                    title: Text("삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제")) {
                        viewModel.deleteTodo(for: date, todo: todo)
                    },
                    secondaryButton: .cancel(Text("취소"))
                )
            } else {
                return Alert(title: Text("오류"), message: Text("선택된 일정이 없습니다."), dismissButton: .default(Text("확인")))
            }
        }
        .confirmationDialog("반복 일정을 삭제할까요?", isPresented: $showDeleteOptions, titleVisibility: .visible) {
            Button("이 일정만 삭제", role: .destructive) {
                if let todo = selectedTodo, let date = selectedDate {
                    viewModel.deleteTodo(for: date, todo: todo)
                }
            }

            Button("반복 일정 모두 삭제", role: .destructive) {
                if let todo = selectedTodo, let date = selectedDate {
                    viewModel.deleteRepeatingTodos(startingFrom: date, text: todo.text)
                }
            }

            Button("취소", role: .cancel) {}
        }

    }

    @ViewBuilder
    private func calendarCell(for day: CalendarDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatDisplayDate(day.date))
                .foregroundColor(day.date == getToday() ? AppColors.textHighlighted : AppColors.textColor1)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .onTapGesture {
                    selectedDate = day.date
                }
                .onDrop(of: [.text], isTargeted: nil) { providers in
                    handleDrop(providers, for: day.date)
                }

            todoList(for: day)
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .frame(minWidth: 120, maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
    }

    @ViewBuilder
    private func todoList(for day: CalendarDay) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let matchedDay = viewModel.dates.first(where: { $0.date == day.date }) {
                ForEach(matchedDay.todos.prefix(maxTodosToShow), id: \..id) { todo in
                    todoView(todo, for: matchedDay.date)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .background(AppColors.color(for: todo.colorName).opacity(0.5))
                }

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

    func formatDisplayDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "d"
            return formatter.string(from: date)
        }
        return dateString
    }

    @ViewBuilder
    private func todoView(_ todo: TodoItem, for date: String) -> some View {
        Text(todo.text)
            .font(.caption)
            .foregroundColor(AppColors.textColor1)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                selectedTodo = todo
                selectedDate = date

                // ⚠️ 하나만 true 되도록
                if todo.isRepeating {
                    showDeleteOptions = true
                    isShowingAlert = false
                } else {
                    showDeleteOptions = false
                    isShowingAlert = true
                }
            }
            .onDrag {
                selectedDate = date
                print("✅ Drag started for \(todo.text) from \(date)")
                return NSItemProvider(object: todo.text as NSString)
            }
    }

    private func handleDrop(_ providers: [NSItemProvider], for targetDate: String) -> Bool {
        print("📌 handleDrop triggered for \(targetDate)")

        if let provider = providers.first {
            provider.loadObject(ofClass: String.self) { droppedTodo, _ in
                print("📌 Loaded Object: \(droppedTodo ?? "nil")")
                if let droppedTodo = droppedTodo, let sourceDate = selectedDate {
                    DispatchQueue.main.async {
                        print("📌 Moving Todo: \(droppedTodo) from \(sourceDate) to \(targetDate)")
                        viewModel.moveTodo(from: sourceDate, to: targetDate, todoText: droppedTodo)
                    }
                } else {
                    print("❌ Failed to retrieve droppedTodo or sourceDate is nil")
                }
            }
            return true
        }
        return false
    }
}
