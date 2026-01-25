//
//  Event.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 일정 데이터 모델
/// macOS와 iOS에서 동일하게 사용되는 핵심 엔티티입니다.
/// 날짜 기반 및 시간 기반 일정을 모두 지원합니다.
public struct Event: Identifiable, Codable, Hashable, Sendable {
    // MARK: - Properties

    /// 고유 식별자
    public var id: UUID

    /// 일정 제목
    public let title: String

    /// 색상 테마
    public let colorTheme: ColorTheme

    /// 시작 일시
    public let startDateTime: Date

    /// 종료 일시
    public let endDateTime: Date

    /// 하루 종일 일정 여부
    public let isAllDay: Bool

    /// 시간대 정보
    public let timeZone: TimeZone

    /// 반복 규칙 (nil = 반복 없음)
    public let recurrenceRule: RecurrenceRule?

    /// 알림 목록
    public let reminders: [Reminder]

    /// 생성 일시
    public let createdAt: Date

    /// 수정 일시
    public let modifiedAt: Date

    /// 동기화 상태
    public var syncStatus: SyncStatus

    /// 위치 정보 (선택적)
    public let location: Location?

    /// 메모 (선택적)
    public let notes: String?

    /// 관련 URL (선택적)
    public let url: URL?

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        title: String,
        colorTheme: ColorTheme = .default,
        startDateTime: Date,
        endDateTime: Date,
        isAllDay: Bool = false,
        timeZone: TimeZone = .current,
        recurrenceRule: RecurrenceRule? = nil,
        reminders: [Reminder] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        syncStatus: SyncStatus = .pending,
        location: Location? = nil,
        notes: String? = nil,
        url: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.colorTheme = colorTheme
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
        self.isAllDay = isAllDay
        self.timeZone = timeZone
        self.recurrenceRule = recurrenceRule
        self.reminders = reminders
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.syncStatus = syncStatus
        self.location = location
        self.notes = notes
        self.url = url
    }

    // MARK: - Hashable

    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, title, colorTheme, startDateTime, endDateTime, isAllDay
        case timeZoneIdentifier, recurrenceRule, reminders
        case createdAt, modifiedAt, syncStatus, location, notes, url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        colorTheme = try container.decode(ColorTheme.self, forKey: .colorTheme)
        startDateTime = try container.decode(Date.self, forKey: .startDateTime)
        endDateTime = try container.decode(Date.self, forKey: .endDateTime)
        isAllDay = try container.decode(Bool.self, forKey: .isAllDay)

        let tzIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        timeZone = TimeZone(identifier: tzIdentifier) ?? .current

        recurrenceRule = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrenceRule)
        reminders = try container.decodeIfPresent([Reminder].self, forKey: .reminders) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        syncStatus = try container.decodeIfPresent(SyncStatus.self, forKey: .syncStatus) ?? .synced
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(colorTheme, forKey: .colorTheme)
        try container.encode(startDateTime, forKey: .startDateTime)
        try container.encode(endDateTime, forKey: .endDateTime)
        try container.encode(isAllDay, forKey: .isAllDay)
        try container.encode(timeZone.identifier, forKey: .timeZoneIdentifier)
        try container.encodeIfPresent(recurrenceRule, forKey: .recurrenceRule)
        try container.encode(reminders, forKey: .reminders)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encode(syncStatus, forKey: .syncStatus)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(url, forKey: .url)
    }
}

// MARK: - Computed Properties

public extension Event {
    /// 일정 기간 (초)
    var duration: TimeInterval {
        endDateTime.timeIntervalSince(startDateTime)
    }

    /// 일정 기간 (분)
    var durationInMinutes: Int {
        Int(duration / 60)
    }

    /// 일정 기간 (일)
    var durationInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDateTime, to: endDateTime)
        return (components.day ?? 0) + 1
    }

    /// 여러 날에 걸친 일정인지 확인
    var isMultiDay: Bool {
        let calendar = Calendar.current
        return !calendar.isDate(startDateTime, inSameDayAs: endDateTime)
    }

    /// 반복 일정인지 확인
    var isRecurring: Bool {
        recurrenceRule != nil
    }

    /// 알림이 설정되어 있는지 확인
    var hasReminders: Bool {
        !reminders.isEmpty
    }

    /// 특정 날짜가 이 일정 기간에 포함되는지 확인
    /// - Parameter date: 확인할 날짜
    /// - Returns: 포함 여부
    func includesDate(_ date: Date) -> Bool {
        let calendar = Calendar.current

        if isAllDay {
            let startDay = calendar.startOfDay(for: startDateTime)
            let endDay = calendar.startOfDay(for: endDateTime)
            let checkDay = calendar.startOfDay(for: date)
            return checkDay >= startDay && checkDay <= endDay
        } else {
            return date >= startDateTime && date <= endDateTime
        }
    }

    /// 특정 날짜의 시작 시점인지 확인
    /// - Parameter date: 확인할 날짜
    /// - Returns: 시작 여부
    func startsOn(_ date: Date) -> Bool {
        Calendar.current.isDate(startDateTime, inSameDayAs: date)
    }

    /// 특정 날짜의 종료 시점인지 확인
    /// - Parameter date: 확인할 날짜
    /// - Returns: 종료 여부
    func endsOn(_ date: Date) -> Bool {
        Calendar.current.isDate(endDateTime, inSameDayAs: date)
    }

    /// 시작 시간 문자열 (HH:mm 형식)
    var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        return formatter.string(from: startDateTime)
    }

    /// 종료 시간 문자열 (HH:mm 형식)
    var endTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        return formatter.string(from: endDateTime)
    }

    /// 시간 범위 문자열 (예: "14:00 - 15:30")
    var timeRangeString: String {
        if isAllDay {
            return "하루 종일"
        }
        return "\(startTimeString) - \(endTimeString)"
    }

    /// 날짜 문자열 (yyyy-MM-dd 형식)
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone
        return formatter.string(from: startDateTime)
    }
}

// MARK: - Factory Methods

public extension Event {
    /// 하루 종일 일정 생성
    /// - Parameters:
    ///   - title: 일정 제목
    ///   - date: 날짜
    ///   - colorTheme: 색상 테마
    /// - Returns: 새 Event 인스턴스
    static func allDay(
        title: String,
        date: Date,
        colorTheme: ColorTheme = .default
    ) -> Event {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        var endComponents = DateComponents()
        endComponents.day = 1
        endComponents.second = -1
        let endOfDay = calendar.date(byAdding: endComponents, to: startOfDay) ?? startOfDay

        return Event(
            title: title,
            colorTheme: colorTheme,
            startDateTime: startOfDay,
            endDateTime: endOfDay,
            isAllDay: true
        )
    }

    /// 여러 날에 걸친 하루 종일 일정 생성
    /// - Parameters:
    ///   - title: 일정 제목
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - colorTheme: 색상 테마
    /// - Returns: 새 Event 인스턴스
    static func allDayPeriod(
        title: String,
        startDate: Date,
        endDate: Date,
        colorTheme: ColorTheme = .default
    ) -> Event {
        let calendar = Calendar.current
        let startOfStartDay = calendar.startOfDay(for: startDate)
        let startOfEndDay = calendar.startOfDay(for: endDate)
        var endComponents = DateComponents()
        endComponents.day = 1
        endComponents.second = -1
        let endOfEndDay = calendar.date(byAdding: endComponents, to: startOfEndDay) ?? startOfEndDay

        return Event(
            title: title,
            colorTheme: colorTheme,
            startDateTime: startOfStartDay,
            endDateTime: endOfEndDay,
            isAllDay: true
        )
    }

    /// 시간 기반 일정 생성
    /// - Parameters:
    ///   - title: 일정 제목
    ///   - start: 시작 일시
    ///   - end: 종료 일시
    ///   - colorTheme: 색상 테마
    /// - Returns: 새 Event 인스턴스
    static func timed(
        title: String,
        start: Date,
        end: Date,
        colorTheme: ColorTheme = .default
    ) -> Event {
        Event(
            title: title,
            colorTheme: colorTheme,
            startDateTime: start,
            endDateTime: end,
            isAllDay: false
        )
    }

    /// 시간 기반 일정 생성 (기간 지정)
    /// - Parameters:
    ///   - title: 일정 제목
    ///   - start: 시작 일시
    ///   - duration: 기간 (분)
    ///   - colorTheme: 색상 테마
    /// - Returns: 새 Event 인스턴스
    static func timed(
        title: String,
        start: Date,
        durationMinutes: Int,
        colorTheme: ColorTheme = .default
    ) -> Event {
        let end = start.addingTimeInterval(Double(durationMinutes) * 60)
        return Event(
            title: title,
            colorTheme: colorTheme,
            startDateTime: start,
            endDateTime: end,
            isAllDay: false
        )
    }

    /// 기본 템플릿 생성 (NL 파싱용)
    static func template() -> Event {
        Event(
            title: "",
            colorTheme: .default,
            startDateTime: Date(),
            endDateTime: Date().addingTimeInterval(3600),
            isAllDay: true
        )
    }
}

// MARK: - Mutation Helpers

public extension Event {
    /// 수정된 복사본 생성
    /// - Parameter modifications: 수정할 값들을 클로저로 전달
    /// - Returns: 수정된 새 Event 인스턴스
    func updated(
        title: String? = nil,
        colorTheme: ColorTheme? = nil,
        startDateTime: Date? = nil,
        endDateTime: Date? = nil,
        isAllDay: Bool? = nil,
        timeZone: TimeZone? = nil,
        recurrenceRule: RecurrenceRule?? = nil,
        reminders: [Reminder]? = nil,
        location: Location?? = nil,
        notes: String?? = nil,
        url: URL?? = nil
    ) -> Event {
        Event(
            id: self.id,
            title: title ?? self.title,
            colorTheme: colorTheme ?? self.colorTheme,
            startDateTime: startDateTime ?? self.startDateTime,
            endDateTime: endDateTime ?? self.endDateTime,
            isAllDay: isAllDay ?? self.isAllDay,
            timeZone: timeZone ?? self.timeZone,
            recurrenceRule: recurrenceRule ?? self.recurrenceRule,
            reminders: reminders ?? self.reminders,
            createdAt: self.createdAt,
            modifiedAt: Date(),
            syncStatus: .pending,
            location: location ?? self.location,
            notes: notes ?? self.notes,
            url: url ?? self.url
        )
    }

    /// 알림 추가
    func addingReminder(_ reminder: Reminder) -> Event {
        var newReminders = reminders
        newReminders.append(reminder)
        return updated(reminders: newReminders)
    }

    /// 알림 제거
    func removingReminder(_ reminder: Reminder) -> Event {
        let newReminders = reminders.filter { $0.id != reminder.id }
        return updated(reminders: newReminders)
    }

    /// 동기화 상태 변경
    func withSyncStatus(_ status: SyncStatus) -> Event {
        var copy = self
        copy.syncStatus = status
        return copy
    }
}
