//
//  CalendarDayGenerator.swift
//  Nower
//
//  Created by 신종원 on 4/12/25.
//

import Foundation

struct CalendarDayGenerator {
    static func generate(for date: Date, todos: [TodoItem]) -> [CalendarDay] {
        var days: [CalendarDay] = []

        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date) else { return days }
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        let prevMonthDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        for _ in 0..<prevMonthDays {
            days.append(CalendarDay(date: "", todos: []))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for day in monthRange {
            var components = calendar.dateComponents([.year, .month], from: date)
            components.day = day
            if let dayDate = calendar.date(from: components) {
                let dateString = formatter.string(from: dayDate)
                let dayTodos = todos.filter { $0.date == dateString }
                days.append(CalendarDay(date: dateString, todos: dayTodos))
            }
        }

        return days
    }
}
