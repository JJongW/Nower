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
    @State private var isShowingEditPopup = false
    @State private var showDeleteOptions = false

    @Binding var toastMessage: String
    @Binding var showToast: Bool

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
        .sheet(isPresented: $isShowingEditPopup) {
            EditTodoSheetWrapper(
                selectedTodo: selectedTodo,
                selectedDate: selectedDate,
                isPresented: $isShowingEditPopup,
                showToast: $showToast,
                toastMessage: $toastMessage
            )
            .environmentObject(viewModel)
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
            }
            .onChange(of: selectedDate) { _ in
                if selectedTodo != nil && selectedDate != nil {
                    isShowingEditPopup = true
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
                        show(message: "⏱️ 일정이 이동되었습니다.")
                    }
                } else {
                    print("❌ Failed to retrieve droppedTodo or sourceDate is nil")
                }
            }
            return true
        }
        return false
    }

    func show(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

struct EditTodoSheetWrapper: View {
    let selectedTodo: TodoItem?
    let selectedDate: String?
    @Binding var isPresented: Bool
    @Binding var showToast: Bool
    @Binding var toastMessage: String

    @EnvironmentObject var viewModel: CalendarViewModel

    var body: some View {
        if let todo = selectedTodo, let date = selectedDate {
            EditTodoPopupView(todo: todo, date: date, isPresented: $isPresented, showToast: $showToast, toastMessage: $toastMessage)
                .environmentObject(viewModel)
        } else {
            EmptyView()
        }
    }
}
