//
//  CalendarDay.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 캘린더의 하루를 나타내는 모델
public struct CalendarDay: Identifiable, Hashable, Sendable {
    public var id: UUID
    public let date: Date
    public let events: [Event]
    public let holidayName: String?

    /// 빈 날짜 셀인지 (패딩용)
    public let isEmpty: Bool

    public init(
        id: UUID = UUID(),
        date: Date,
        events: [Event] = [],
        holidayName: String? = nil,
        isEmpty: Bool = false
    ) {
        self.id = id
        self.date = date
        self.events = events
        self.holidayName = holidayName
        self.isEmpty = isEmpty
    }

    // MARK: - Hashable

    public static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Computed Properties

public extension CalendarDay {
    /// 일정이 있는지 확인
    var hasEvents: Bool {
        !events.isEmpty
    }

    /// 일정 개수
    var eventCount: Int {
        events.count
    }

    /// 오늘인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// 공휴일인지 확인
    var isHoliday: Bool {
        holidayName != nil
    }

    /// 주말인지 확인
    var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    /// 특정 색상의 일정 개수
    func eventCount(for colorTheme: ColorTheme) -> Int {
        events.filter { $0.colorTheme == colorTheme }.count
    }

    /// 하루 종일 일정만 필터링
    var allDayEvents: [Event] {
        events.filter { $0.isAllDay }
    }

    /// 시간 지정 일정만 필터링
    var timedEvents: [Event] {
        events.filter { !$0.isAllDay }
    }

    /// 기간별 일정만 필터링 (여러 날에 걸친 일정)
    var periodEvents: [Event] {
        events.filter { $0.isMultiDay }
    }

    /// 단일 날짜 일정만 필터링
    var singleDayEvents: [Event] {
        events.filter { !$0.isMultiDay }
    }

    /// 날짜 문자열 (yyyy-MM-dd)
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// 일자 (1-31)
    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
}

// MARK: - Factory Methods

public extension CalendarDay {
    /// 빈 패딩 셀 생성
    static func empty() -> CalendarDay {
        CalendarDay(
            date: Date.distantPast,
            isEmpty: true
        )
    }

    /// 일정을 추가한 새 CalendarDay 반환
    func adding(_ event: Event) -> CalendarDay {
        CalendarDay(
            id: id,
            date: date,
            events: events + [event],
            holidayName: holidayName,
            isEmpty: isEmpty
        )
    }

    /// 일정을 제거한 새 CalendarDay 반환
    func removing(_ event: Event) -> CalendarDay {
        CalendarDay(
            id: id,
            date: date,
            events: events.filter { $0.id != event.id },
            holidayName: holidayName,
            isEmpty: isEmpty
        )
    }
}
