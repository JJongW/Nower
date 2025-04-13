//
//  CalendarViewModel.swift
//  Nower
//
//  Created by 신종원 on 3/9/25.
//
import SwiftUI
import Foundation

class CalendarViewModel: ObservableObject {
    @Published var dates: [CalendarDay] = []
    @Published var currentMonth: Date = Date()
    @Published var isAddingEvent: Bool = false
    @Published var selectedEventType: EventType = .normal

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(todosUpdated), name: .init("TodosUpdated"), object: nil)
        generateCalendarDays(for: currentMonth)
    }

    func changeMonth(by value: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            DispatchQueue.main.async {
                self.currentMonth = newDate
                self.generateCalendarDays(for: newDate)
            }
        }
    }

    func generateCalendarDays(for date: Date) {
        DispatchQueue.main.async {
            self.dates = CalendarDayGenerator.generate(for: date, todos: EventManager.shared.todos)
        }
    }

    func addTodo(for date: Date, text: String, colorName: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let newTodo = TodoItem(
            text: text,
            isRepeating: false,
            date: dateString,
            colorName: colorName
        )

        EventManager.shared.addTodo(newTodo)
        generateCalendarDays(for: currentMonth)
    }

    func deleteTodo(todo: TodoItem) {
        EventManager.shared.deleteTodo(todo)
        generateCalendarDays(for: currentMonth)
    }

    @objc private func todosUpdated() {
        generateCalendarDays(for: currentMonth)
    }

    func moveTodo(from oldDate: String, to newDate: String, todoText: String) {
        guard oldDate != newDate else { return }

        if let todoToMove = EventManager.shared.todos.first(where: { $0.date == oldDate && $0.text == todoText }) {
            EventManager.shared.deleteTodo(todoToMove)

            let newTodo = TodoItem(
                text: todoText,
                isRepeating: todoToMove.isRepeating,
                date: newDate,
                colorName: todoToMove.colorName
            )

            EventManager.shared.addTodo(newTodo)

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .init("TodosUpdated"), object: nil)
            }
        } else {
            print("❌ 이동할 Todo를 찾을 수 없습니다")
        }
    }

}
