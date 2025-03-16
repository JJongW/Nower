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

    let context = PersistenceController.shared.context

    init() {
        debugPrintCoreData()
        loadTodos() // ✅ CoreData에서 데이터 불러오기
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

        // Add previous month's trailing days
        let prevMonthDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        for _ in 0..<prevMonthDays {
            days.append(CalendarDay(date: "", todos: []))
        }

        // Add actual days
        for day in monthRange {
            let formattedDate = formatDateForCoreData(day: day, month: date)
            days.append(CalendarDay(date: formattedDate, todos: []))
        }

        DispatchQueue.main.async {
            self.dates = days
            self.loadTodos() // ✅ CoreData 데이터 반영 추가
        }
    }

    // ✅ CoreData에서 사용하는 날짜 형식으로 변환하는 함수
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


    func addTodo(for date: String, todo: String) {
        guard !todo.isEmpty else { return }

        let request: NSFetchRequest<CalendarDayEntity> = CalendarDayEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date)

        do {
            let results = try context.fetch(request)
            let calendarDay: CalendarDayEntity

            if let existingDay = results.first {
                calendarDay = existingDay // ✅ 기존 날짜가 있으면 재사용
            } else {
                calendarDay = CalendarDayEntity(context: context)
                calendarDay.date = date // ✅ 새 날짜를 추가할 경우에만 생성
            }

            let newTodo = TodoEntity(context: context)
            newTodo.text = todo
            newTodo.dateRelation = calendarDay

            try context.save()

            DispatchQueue.main.async {
                self.loadTodos() // ✅ 기존 날짜 유지하면서 일정 추가
                print("✅ Todo added for \(date): \(todo)") // 디버깅: 일정이 제대로 추가되는지 확인
            }
        } catch {
            print("❌ Failed to save todo: \(error)")
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

            print("📌 CoreData Results: \(results.map { "\($0.date ?? "No Date") - \($0.todos?.count ?? 0) todos" })")

            var updatedDates = self.dates

            for entity in results {
                if let index = updatedDates.firstIndex(where: { $0.date == entity.date }) {
                    // ✅ 기존 날짜에 일정 추가
                    let newTodos = (entity.todos as? Set<TodoEntity>)?.compactMap { $0.text }.map { TodoItem(text: $0) } ?? []
                    updatedDates[index].todos.append(contentsOf: newTodos)
                }
            }

            DispatchQueue.main.async {
                self.dates = updatedDates
                print("✅ Updated Dates in ViewModel: \(self.dates.map { "\($0.date) - \($0.todos.count) todos" })")

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


}
