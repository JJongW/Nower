//
//  CalendarDayGenerator.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 캘린더 날짜 생성 유틸리티
public enum CalendarDayGenerator {
    /// 월별 CalendarDay 배열 생성
    /// - Parameters:
    ///   - date: 기준 날짜 (해당 월)
    ///   - events: 표시할 이벤트 목록
    ///   - holidayNameProvider: 공휴일 이름 조회 클로저
    /// - Returns: CalendarDay 배열
    public static func generate(
        for date: Date,
        events: [Event],
        holidayNameProvider: ((Date) -> String?)? = nil
    ) -> [CalendarDay] {
        let calendar = Calendar.current

        // 월의 시작일과 마지막일 계산
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        let firstDayOfMonth = monthInterval.start
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30

        // 첫 번째 날의 요일 (1=일요일)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // 앞쪽 빈 칸 추가 (일요일 시작 기준)
        let leadingEmptyDays = firstWeekday - 1

        var days: [CalendarDay] = []

        // 앞쪽 빈 셀
        for _ in 0..<leadingEmptyDays {
            days.append(.empty())
        }

        // 실제 날짜들
        for dayOffset in 0..<daysInMonth {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) else {
                continue
            }

            // 해당 날짜의 이벤트 필터링
            let dayEvents = events.filter { $0.includesDate(dayDate) }
                .sorted { $0.startDateTime < $1.startDateTime }

            let day = CalendarDay(
                date: dayDate,
                events: dayEvents,
                holidayName: holidayNameProvider?(dayDate)
            )

            days.append(day)
        }

        // 뒤쪽 빈 칸 (7의 배수로 맞춤)
        let totalCells = days.count
        let trailingEmptyDays = (7 - (totalCells % 7)) % 7
        for _ in 0..<trailingEmptyDays {
            days.append(.empty())
        }

        return days
    }

    /// 주별 WeekDayInfo 배열 생성
    /// - Parameters:
    ///   - date: 기준 날짜 (해당 월)
    ///   - events: 표시할 이벤트 목록
    ///   - holidayNameProvider: 공휴일 이름 조회 클로저
    /// - Returns: 주별 WeekDayInfo 2차원 배열
    public static func generateWeeks(
        for date: Date,
        events: [Event],
        holidayNameProvider: ((Date) -> String?)? = nil
    ) -> [[WeekDayInfo]] {
        let calendar = Calendar.current

        // 월의 시작일 계산
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        let firstDayOfMonth = monthInterval.start
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30

        // 첫 번째 날의 요일
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingEmptyDays = firstWeekday - 1

        var allDays: [WeekDayInfo] = []

        // 앞쪽 빈 셀
        for _ in 0..<leadingEmptyDays {
            allDays.append(.empty())
        }

        // 실제 날짜들
        for dayOffset in 0..<daysInMonth {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonth) else {
                continue
            }

            // 해당 날짜의 이벤트 필터링
            let dayEvents = events.filter { $0.includesDate(dayDate) }
                .sorted { $0.startDateTime < $1.startDateTime }

            let weekday = calendar.component(.weekday, from: dayDate)

            let dayInfo = WeekDayInfo(
                date: dayDate,
                dayNumber: dayOffset + 1,
                isToday: calendar.isDateInToday(dayDate),
                isWeekend: weekday == 1 || weekday == 7,
                isEmpty: false,
                holidayName: holidayNameProvider?(dayDate),
                events: dayEvents
            )

            allDays.append(dayInfo)
        }

        // 뒤쪽 빈 칸
        let totalCells = allDays.count
        let trailingEmptyDays = (7 - (totalCells % 7)) % 7
        for _ in 0..<trailingEmptyDays {
            allDays.append(.empty())
        }

        // 주별로 분할
        var weeks: [[WeekDayInfo]] = []
        for i in stride(from: 0, to: allDays.count, by: 7) {
            let week = Array(allDays[i..<min(i + 7, allDays.count)])
            weeks.append(week)
        }

        return weeks
    }

    /// 특정 주의 날짜 범위 계산
    /// - Parameters:
    ///   - date: 기준 날짜
    ///   - startOnSunday: 일요일 시작 여부 (false면 월요일 시작)
    /// - Returns: 주의 시작일과 종료일
    public static func weekRange(for date: Date, startOnSunday: Bool = true) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        let daysToSubtract: Int
        if startOnSunday {
            daysToSubtract = weekday - 1
        } else {
            daysToSubtract = (weekday + 5) % 7
        }

        let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: date)!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        return (weekStart.startOfDay, weekEnd.endOfDay)
    }

    /// 월의 주 수 계산
    /// - Parameter date: 기준 날짜
    /// - Returns: 해당 월의 주 수
    public static func numberOfWeeks(in date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.range(of: .weekOfMonth, in: .month, for: date)?.count ?? 5
    }
}
