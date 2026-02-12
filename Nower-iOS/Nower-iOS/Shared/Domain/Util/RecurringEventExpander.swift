//
//  RecurringEventExpander.swift
//  Nower-iOS
//
//  반복 일정의 가상 인스턴스를 생성하는 유틸리티
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

enum RecurringEventExpander {

    private static let calendar = Calendar.current
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Public API

    /// 특정 날짜에 해당 반복 일정이 발생하는지 확인하고 가상 인스턴스를 반환합니다.
    /// - Parameters:
    ///   - todo: 반복 규칙이 설정된 원본 TodoItem
    ///   - date: 확인할 날짜
    /// - Returns: 해당 날짜에 발생하면 가상 인스턴스, 아니면 nil
    static func occurrence(of todo: TodoItem, on date: Date) -> TodoItem? {
        guard let info = todo.recurrenceInfo,
              let originDate = todo.dateObject else { return nil }

        let targetString = dateFormatter.string(from: date)

        // 예외 확인
        if let exceptions = todo.recurrenceExceptions {
            for exception in exceptions {
                if exception.originalDate == targetString {
                    if exception.isDeleted { return nil }
                    if let override = exception.overriddenTodo {
                        return override
                    }
                }
            }
        }

        // 원본 날짜와 동일한 경우
        if calendar.isDate(originDate, inSameDayAs: date) {
            return todo.virtualInstance(for: date)
        }

        // 대상이 원본보다 이전이면 발생 안 함
        guard date >= originDate else { return nil }

        // 종료일 체크
        if let endDateStr = info.endDate,
           let endDate = dateFormatter.date(from: endDateStr),
           date > endDate {
            return nil
        }

        if matchesRecurrence(info: info, originDate: originDate, targetDate: date, todo: todo) {
            return todo.virtualInstance(for: date)
        }

        return nil
    }

    /// 날짜 범위 내 모든 반복 발생 인스턴스를 반환합니다.
    /// - Parameters:
    ///   - todo: 반복 규칙이 설정된 원본 TodoItem
    ///   - from: 시작 날짜
    ///   - to: 종료 날짜
    /// - Returns: 범위 내 가상 인스턴스 배열
    static func occurrences(of todo: TodoItem, from: Date, to: Date) -> [TodoItem] {
        guard let info = todo.recurrenceInfo,
              let originDate = todo.dateObject else { return [] }

        var results: [TodoItem] = []
        let effectiveStart = max(originDate, from)

        // 종료일 체크
        let effectiveEnd: Date
        if let endDateStr = info.endDate,
           let endDate = dateFormatter.date(from: endDateStr) {
            effectiveEnd = min(endDate, to)
        } else {
            effectiveEnd = to
        }

        guard effectiveStart <= effectiveEnd else { return [] }

        // endAfterCount 지원을 위한 카운터
        let maxCount = info.endAfterCount ?? Int.max
        var count = 0

        // 원본 날짜부터 시작하여 모든 발생을 순회
        var current = originDate

        while current <= effectiveEnd && count < maxCount {
            if current >= effectiveStart {
                let dateString = dateFormatter.string(from: current)

                // 예외 확인
                var isExcluded = false
                var overrideItem: TodoItem?
                if let exceptions = todo.recurrenceExceptions {
                    for exception in exceptions where exception.originalDate == dateString {
                        if exception.isDeleted {
                            isExcluded = true
                        } else if let override = exception.overriddenTodo {
                            overrideItem = override
                        }
                    }
                }

                if !isExcluded {
                    if let override = overrideItem {
                        results.append(override)
                    } else {
                        results.append(todo.virtualInstance(for: current))
                    }
                }
            }

            count += 1

            // 다음 발생 날짜 계산
            guard let next = nextOccurrence(info: info, originDate: originDate, after: current) else { break }
            if next <= current { break } // 무한 루프 방지
            current = next
        }

        return results
    }

    // MARK: - Private Helpers

    /// 특정 날짜가 반복 규칙에 맞는지 확인합니다.
    private static func matchesRecurrence(info: RecurrenceInfo, originDate: Date, targetDate: Date, todo: TodoItem) -> Bool {
        let interval = info.interval

        switch info.frequency {
        case "daily":
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: originDate), to: calendar.startOfDay(for: targetDate)).day ?? 0
            guard days >= 0 else { return false }
            if days % interval != 0 { return false }
            // endAfterCount 체크
            if let maxCount = info.endAfterCount, (days / interval) >= maxCount { return false }
            return true

        case "weekly":
            let targetWeekday = calendar.component(.weekday, from: targetDate)

            if let daysOfWeek = info.daysOfWeek, !daysOfWeek.isEmpty {
                guard daysOfWeek.contains(targetWeekday) else { return false }
                // 주 간격 체크
                if interval > 1 {
                    let weeks = calendar.dateComponents([.weekOfYear], from: calendar.startOfDay(for: originDate), to: calendar.startOfDay(for: targetDate)).weekOfYear ?? 0
                    if weeks % interval != 0 { return false }
                }
                return checkEndAfterCount(info: info, originDate: originDate, targetDate: targetDate, todo: todo)
            } else {
                // 요일 지정 없으면 원래 요일 기준
                let originWeekday = calendar.component(.weekday, from: originDate)
                guard targetWeekday == originWeekday else { return false }
                let weeks = calendar.dateComponents([.weekOfYear], from: calendar.startOfDay(for: originDate), to: calendar.startOfDay(for: targetDate)).weekOfYear ?? 0
                guard weeks >= 0 else { return false }
                if weeks % interval != 0 { return false }
                return checkEndAfterCount(info: info, originDate: originDate, targetDate: targetDate, todo: todo)
            }

        case "monthly":
            let originComponents = calendar.dateComponents([.year, .month, .day], from: originDate)
            let targetComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)

            let targetDay = info.dayOfMonth ?? (originComponents.day ?? 1)
            let actualDay = targetComponents.day ?? 1

            // 해당 월의 최대 일자 고려
            let daysInMonth = calendar.range(of: .day, in: .month, for: targetDate)?.count ?? 31
            let adjustedDay = min(targetDay, daysInMonth)
            guard actualDay == adjustedDay else { return false }

            // 월 간격 체크
            let monthDiff = (targetComponents.year! - originComponents.year!) * 12 + (targetComponents.month! - originComponents.month!)
            guard monthDiff >= 0 else { return false }
            if monthDiff % interval != 0 { return false }
            return checkEndAfterCount(info: info, originDate: originDate, targetDate: targetDate, todo: todo)

        case "yearly":
            let originComponents = calendar.dateComponents([.month, .day, .year], from: originDate)
            let targetComponents = calendar.dateComponents([.month, .day, .year], from: targetDate)

            guard targetComponents.month == originComponents.month,
                  targetComponents.day == originComponents.day else { return false }

            let yearDiff = (targetComponents.year ?? 0) - (originComponents.year ?? 0)
            guard yearDiff >= 0 else { return false }
            if yearDiff % interval != 0 { return false }
            return checkEndAfterCount(info: info, originDate: originDate, targetDate: targetDate, todo: todo)

        default:
            return false
        }
    }

    /// endAfterCount를 체크합니다 (occurrences 범위 메서드에서의 카운트와 별도로, 단일 날짜 체크용)
    private static func checkEndAfterCount(info: RecurrenceInfo, originDate: Date, targetDate: Date, todo: TodoItem) -> Bool {
        guard let maxCount = info.endAfterCount else { return true }
        // 해당 날짜까지의 발생 횟수를 카운트
        var count = 0
        var current = originDate
        while current <= targetDate && count < maxCount {
            if calendar.isDate(current, inSameDayAs: targetDate) {
                return true
            }
            count += 1
            guard let next = nextOccurrence(info: info, originDate: originDate, after: current) else { return false }
            if next <= current { return false }
            current = next
        }
        return false
    }

    /// 다음 발생 날짜를 계산합니다.
    private static func nextOccurrence(info: RecurrenceInfo, originDate: Date, after current: Date) -> Date? {
        let interval = info.interval

        switch info.frequency {
        case "daily":
            return calendar.date(byAdding: .day, value: interval, to: current)

        case "weekly":
            if let daysOfWeek = info.daysOfWeek, !daysOfWeek.isEmpty {
                // 이번 주에서 다음 요일 찾기
                var candidate = current
                for _ in 0..<(7 * interval + 7) {
                    guard let next = calendar.date(byAdding: .day, value: 1, to: candidate) else { return nil }
                    let weekday = calendar.component(.weekday, from: next)
                    if daysOfWeek.contains(weekday) {
                        // 주 간격 체크
                        if interval > 1 {
                            let weeks = calendar.dateComponents([.weekOfYear], from: calendar.startOfDay(for: originDate), to: calendar.startOfDay(for: next)).weekOfYear ?? 0
                            if weeks >= 0 && weeks % interval == 0 {
                                return next
                            }
                        } else {
                            return next
                        }
                    }
                    candidate = next
                }
                return nil
            } else {
                return calendar.date(byAdding: .weekOfYear, value: interval, to: current)
            }

        case "monthly":
            guard let nextMonth = calendar.date(byAdding: .month, value: interval, to: current) else { return nil }
            let targetDay = info.dayOfMonth ?? (calendar.component(.day, from: originDate))
            var components = calendar.dateComponents([.year, .month], from: nextMonth)
            let daysInMonth = calendar.range(of: .day, in: .month, for: nextMonth)?.count ?? 31
            components.day = min(targetDay, daysInMonth)
            return calendar.date(from: components)

        case "yearly":
            return calendar.date(byAdding: .year, value: interval, to: current)

        default:
            return nil
        }
    }
}
