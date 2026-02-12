//
//  RecurrenceRule.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 반복 일정 규칙
public struct RecurrenceRule: Codable, Hashable, Sendable {
    /// 반복 빈도
    public enum Frequency: String, Codable, CaseIterable, Sendable {
        case daily      // 매일
        case weekly     // 매주
        case monthly    // 매월
        case yearly     // 매년

        public var displayName: String {
            switch self {
            case .daily: return "매일"
            case .weekly: return "매주"
            case .monthly: return "매월"
            case .yearly: return "매년"
            }
        }
    }

    /// 반복 빈도
    public let frequency: Frequency

    /// 반복 간격 (예: 2 = 2일/2주/2개월마다)
    public let interval: Int

    /// 반복 종료 날짜 (nil = 무한 반복)
    public let endDate: Date?

    /// 주간 반복 시 특정 요일 지정 (1=일요일, 7=토요일)
    public let daysOfWeek: Set<Int>?

    /// 월간 반복 시 특정 일자 지정 (1-31)
    public let dayOfMonth: Int?

    /// N회 후 종료 (endDate 대안)
    public let endAfterCount: Int?

    public init(
        frequency: Frequency,
        interval: Int = 1,
        endDate: Date? = nil,
        daysOfWeek: Set<Int>? = nil,
        dayOfMonth: Int? = nil,
        endAfterCount: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.endDate = endDate
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.endAfterCount = endAfterCount
    }

    /// 다음 발생 날짜 계산
    /// - Parameter from: 기준 날짜
    /// - Returns: 다음 발생 날짜 (종료되었으면 nil)
    public func nextOccurrence(after from: Date) -> Date? {
        let calendar = Calendar.current
        var nextDate: Date?

        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: interval, to: from)

        case .weekly:
            if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
                // 특정 요일 반복
                nextDate = findNextWeekday(after: from, in: daysOfWeek, calendar: calendar)
            } else {
                nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: from)
            }

        case .monthly:
            if let dayOfMonth = dayOfMonth {
                nextDate = findNextMonthlyDate(after: from, day: dayOfMonth, interval: interval, calendar: calendar)
            } else {
                nextDate = calendar.date(byAdding: .month, value: interval, to: from)
            }

        case .yearly:
            nextDate = calendar.date(byAdding: .year, value: interval, to: from)
        }

        // 종료일 확인
        if let end = endDate, let next = nextDate, next > end {
            return nil
        }

        return nextDate
    }

    /// 지정된 기간 내의 모든 발생 날짜 반환
    /// - Parameters:
    ///   - start: 시작 날짜
    ///   - end: 종료 날짜
    ///   - limit: 최대 개수 제한
    /// - Returns: 발생 날짜 배열
    public func occurrences(from start: Date, to end: Date, limit: Int = 100) -> [Date] {
        var occurrences: [Date] = []
        var current = start

        while occurrences.count < limit {
            guard let next = nextOccurrence(after: current) else { break }
            if next > end { break }

            occurrences.append(next)
            current = next
        }

        return occurrences
    }

    /// 표시용 문자열
    public var displayString: String {
        if interval == 1 {
            return frequency.displayName
        } else {
            switch frequency {
            case .daily: return "\(interval)일마다"
            case .weekly: return "\(interval)주마다"
            case .monthly: return "\(interval)개월마다"
            case .yearly: return "\(interval)년마다"
            }
        }
    }

    // MARK: - Private Helpers

    private func findNextWeekday(after date: Date, in weekdays: Set<Int>, calendar: Calendar) -> Date? {
        var current = date
        for _ in 0..<(7 * interval + 7) {
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { return nil }
            let weekday = calendar.component(.weekday, from: next)
            if weekdays.contains(weekday) {
                return next
            }
            current = next
        }
        return nil
    }

    private func findNextMonthlyDate(after date: Date, day: Int, interval: Int, calendar: Calendar) -> Date? {
        guard let nextMonth = calendar.date(byAdding: .month, value: interval, to: date) else { return nil }

        var components = calendar.dateComponents([.year, .month], from: nextMonth)
        components.day = min(day, calendar.range(of: .day, in: .month, for: nextMonth)?.count ?? day)

        return calendar.date(from: components)
    }
}

// MARK: - Preset Rules

public extension RecurrenceRule {
    /// 매일 반복
    static var daily: RecurrenceRule {
        RecurrenceRule(frequency: .daily)
    }

    /// 매주 반복
    static var weekly: RecurrenceRule {
        RecurrenceRule(frequency: .weekly)
    }

    /// 평일만 반복 (월-금)
    static var weekdays: RecurrenceRule {
        RecurrenceRule(frequency: .weekly, daysOfWeek: [2, 3, 4, 5, 6])
    }

    /// 매월 반복
    static var monthly: RecurrenceRule {
        RecurrenceRule(frequency: .monthly)
    }

    /// 매년 반복
    static var yearly: RecurrenceRule {
        RecurrenceRule(frequency: .yearly)
    }
}
