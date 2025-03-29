//
//  CalendarViewModel.swift
//  Nower
//
//  Created by 신종원 on 3/9/25.
//

import SwiftUI
import Foundation
import CoreData

class CalendarViewModel: ObservableObject {
    @Published var dates: [CalendarDay] = []
    @Published var currentMonth: Date = Date()
    @Published var isAddingEvent: Bool = false
    @Published var selectedEventType: EventType = .normal

    let context = PersistenceController.shared.context

    init() {
        debugPrintCoreData()
        loadTodos()
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
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date) else { return }
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        var days: [CalendarDay] = []

        let prevMonthDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        for _ in 0..<prevMonthDays {
            days.append(CalendarDay(date: "", todos: []))
        }

        for day in monthRange {
            let formattedDate = formatDateForCoreData(day: day, month: date)
            days.append(CalendarDay(date: formattedDate, todos: []))
        }

        DispatchQueue.main.async {
            self.dates = days
            self.loadTodos()
        }
    }

    func formatDateForCoreData(day: Int, month: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var components = Calendar.current.dateComponents([.year, .month], from: month)
        components.day = day

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }

    func addTodo(for date: Date, todo: String, repeatOption: RepeatOption, colorName: String) {
        guard !todo.isEmpty else { return }

        let calendar = Calendar.current
        var datesToAdd: [Date] = [date]

        switch repeatOption {
        case .daily:
            datesToAdd = (0..<30).compactMap { calendar.date(byAdding: .day, value: $0, to: date) }
        case .weekly:
            datesToAdd = (0..<12).compactMap { calendar.date(byAdding: .weekOfYear, value: $0, to: date) }
        case .monthly:
            datesToAdd = (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: date) }
        case .yearly:
            datesToAdd = (0..<5).compactMap { calendar.date(byAdding: .year, value: $0, to: date) }
        case .none:
            break
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for date in datesToAdd {
            let dateString = formatter.string(from: date)

            let request: NSFetchRequest<CalendarDayEntity> = CalendarDayEntity.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", dateString)

            do {
                let results = try context.fetch(request)
                let calendarDay: CalendarDayEntity

                if let existingDay = results.first {
                    calendarDay = existingDay
                } else {
                    calendarDay = CalendarDayEntity(context: context)
                    calendarDay.date = dateString
                }

                let newTodo = TodoEntity(context: context)
                newTodo.text = todo
                newTodo.dateRelation = calendarDay
                newTodo.isRepeating = repeatOption != .none
                newTodo.colorName = colorName

                try context.save()

                DispatchQueue.main.async {
                    self.loadTodos()
                    print("✅ Todo added for \(dateString): \(todo), isRepeating = \(newTodo.isRepeating), color = \(colorName)")
                }
            } catch {
                print("❌ Failed to save todo: \(error)")
            }
        }
    }

    func deleteTodo(for date: String, todo: TodoItem) {
        let request: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "text == %@ AND dateRelation.date == %@", todo.text, date)

        do {
            let results = try context.fetch(request)
            for object in results {
                context.delete(object)
            }
            try context.save()

            DispatchQueue.main.async {
                self.loadTodos()
            }
        } catch {
            print("❌ Failed to delete todo: \(error)")
        }
    }

    func loadTodos() {
        let request: NSFetchRequest<CalendarDayEntity> = CalendarDayEntity.fetchRequest()
        do {
            let results = try context.fetch(request)

            print("📌 CoreData Results: \(results.map { "\($0.date ?? "No Date") - \($0.todos?.count ?? 0)" })")

            var updatedDates = self.dates.map { day in
                CalendarDay(date: day.date, todos: [])
            }

            for entity in results {
                if let index = updatedDates.firstIndex(where: { $0.date == entity.date }) {
                    let newTodos: [TodoItem] = (entity.todos as? Set<TodoEntity>)?.compactMap { todo -> TodoItem? in
                        guard let text = todo.text else { return nil }
                        return TodoItem(
                            text: text,
                            isRepeating: todo.isRepeating,
                            date: entity.date ?? "",
                            colorName: todo.colorName ?? ""
                        )
                    } ?? []
                    updatedDates[index].todos = newTodos
                }
            }

            DispatchQueue.main.async {
                self.dates = updatedDates
            }
        } catch {
            print("❌ Failed to fetch todos: \(error)")
        }
    }

    func debugPrintCoreData() {
        let request: NSFetchRequest<CalendarDayEntity> = CalendarDayEntity.fetchRequest()

        do {
            let results = try context.fetch(request)

            print("📌 CoreData 저장된 데이터:")
            for entity in results {
                let todos = (entity.todos as? Set<TodoEntity>)?.compactMap { $0.text } ?? []
                print("📅 날짜: \(entity.date ?? "Unknown Date") - 📋 할 일: \(todos)")
            }
        } catch {
            print("❌ CoreData 데이터를 불러오는 데 실패: \(error)")
        }
    }

    func deleteRepeatingTodos(startingFrom date: String, text: String) {
        let request: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "text == %@ AND dateRelation.date >= %@", text, date)

        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            try context.save()

            print("🗑 반복 일정 \(text) 이후 모두 삭제됨")
            self.loadTodos()
        } catch {
            print("❌ 반복 일정 삭제 실패: \(error)")
        }
    }

    func moveTodo(from oldDate: String, to newDate: String, todoText: String) {
        guard oldDate != newDate else { return }

        let oldRequest: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        oldRequest.predicate = NSPredicate(format: "text == %@ AND dateRelation.date == %@", todoText, oldDate)

        let newRequest: NSFetchRequest<CalendarDayEntity> = CalendarDayEntity.fetchRequest()
        newRequest.predicate = NSPredicate(format: "date == %@", newDate)

        do {
            let oldResults = try context.fetch(oldRequest)
            let newResults = try context.fetch(newRequest)
                if let todoToMove = oldResults.first {
                    let originalColor = todoToMove.colorName
                    context.delete(todoToMove)
                    try context.save()

                    let newDay = newResults.first ?? {
                        let newEntity = CalendarDayEntity(context: context)
                        newEntity.date = newDate
                        return newEntity
                    }()

                    let newTodo = TodoEntity(context: context)
                    newTodo.text = todoText
                    newTodo.dateRelation = newDay
                    newTodo.colorName = originalColor
                    newTodo.isRepeating = todoToMove.isRepeating

                    try context.save()

                    DispatchQueue.main.async {
                        self.loadTodos()
                    }

            } else {
                print("❌ No todo found to move")
            }
        } catch {
            print("❌ Failed to move todo: \(error)")
        }
    }

}
