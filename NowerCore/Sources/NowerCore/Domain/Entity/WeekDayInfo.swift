//
//  WeekDayInfo.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 주간 캘린더에서 하루의 정보를 나타내는 구조체
public struct WeekDayInfo: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let date: Date
    public let dayNumber: Int
    public let isToday: Bool
    public let isWeekend: Bool
    public let isEmpty: Bool
    public let holidayName: String?
    public let events: [Event]

    public init(
        id: UUID = UUID(),
        date: Date,
        dayNumber: Int,
        isToday: Bool = false,
        isWeekend: Bool = false,
        isEmpty: Bool = false,
        holidayName: String? = nil,
        events: [Event] = []
    ) {
        self.id = id
        self.date = date
        self.dayNumber = dayNumber
        self.isToday = isToday
        self.isWeekend = isWeekend
        self.isEmpty = isEmpty
        self.holidayName = holidayName
        self.events = events
    }

    // MARK: - Hashable

    public static func == (lhs: WeekDayInfo, rhs: WeekDayInfo) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Computed Properties

public extension WeekDayInfo {
    /// 일정이 있는지 확인
    var hasEvents: Bool {
        !events.isEmpty
    }

    /// 일정 개수
    var eventCount: Int {
        events.count
    }

    /// 공휴일인지 확인
    var isHoliday: Bool {
        holidayName != nil
    }

    /// 하루 종일 일정만 필터링
    var allDayEvents: [Event] {
        events.filter { $0.isAllDay }
    }

    /// 시간 지정 일정만 필터링
    var timedEvents: [Event] {
        events.filter { !$0.isAllDay }
    }

    /// 기간별 일정 필터링
    var periodEvents: [Event] {
        events.filter { $0.isMultiDay }
    }

    /// 단일 날짜 일정 필터링
    var singleDayEvents: [Event] {
        events.filter { !$0.isMultiDay }
    }

    /// 날짜 문자열 (yyyy-MM-dd)
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Factory Methods

public extension WeekDayInfo {
    /// 빈 패딩 셀 생성
    static func empty() -> WeekDayInfo {
        WeekDayInfo(
            date: Date.distantPast,
            dayNumber: 0,
            isEmpty: true
        )
    }

    /// CalendarDay에서 WeekDayInfo 생성
    static func from(_ calendarDay: CalendarDay) -> WeekDayInfo {
        WeekDayInfo(
            id: calendarDay.id,
            date: calendarDay.date,
            dayNumber: calendarDay.dayNumber,
            isToday: calendarDay.isToday,
            isWeekend: calendarDay.isWeekend,
            isEmpty: calendarDay.isEmpty,
            holidayName: calendarDay.holidayName,
            events: calendarDay.events
        )
    }
}
