//
//  AppleCalendarProvider.swift
//  NowerCore
//
//  EventKit 기반 Apple 캘린더 읽기 전용 provider.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

#if canImport(EventKit)
import EventKit

public final class AppleCalendarProvider: CalendarProvider {
    public let source: CalendarSource = .apple

    private let store = EKEventStore()
    /// 포함할 캘린더 식별자. nil이면 전체.
    private let calendarIdentifiers: [String]?

    public init(calendarIdentifiers: [String]? = nil) {
        self.calendarIdentifiers = calendarIdentifiers
    }

    /// 현재 캘린더 접근 권한이 이미 허용 상태인지.
    public static var isAuthorized: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    public func authorize() async -> Bool {
        #if os(watchOS)
        // watchOS는 읽기 전용 미러 대상에서 제외.
        return false
        #else
        if #available(iOS 17.0, macOS 14.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
        #endif
    }

    public func fetchEvents(in range: DateInterval) async throws -> [ExternalEvent] {
        #if os(watchOS)
        return []
        #else
        guard Self.isAuthorized else { return [] }

        let calendars: [EKCalendar]?
        if let ids = calendarIdentifiers {
            calendars = store.calendars(for: .event).filter { ids.contains($0.calendarIdentifier) }
        } else {
            calendars = nil // 전체
        }

        let predicate = store.predicateForEvents(withStart: range.start, end: range.end, calendars: calendars)
        // events(matching:)는 반복 이벤트를 발생별로 이미 전개해서 돌려준다.
        let ekEvents = store.events(matching: predicate)

        return ekEvents.map { event in
            let baseID = event.eventIdentifier ?? UUID().uuidString
            let occurrenceID = baseID + "@" + String(Int(event.startDate.timeIntervalSince1970))
            return ExternalEvent(
                source: .apple,
                externalID: occurrenceID,
                title: event.title ?? "",
                start: event.startDate,
                end: event.endDate,
                isAllDay: event.isAllDay,
                calendarTitle: event.calendar?.title ?? "",
                colorName: Self.themeColorName(for: event.calendar)
            )
        }
        #endif
    }

    #if !os(watchOS)
    /// 사용 가능한 이벤트 캘린더 목록(설정 UI에서 선택용). (식별자, 표시명).
    public func availableCalendars() -> [(id: String, title: String)] {
        store.calendars(for: .event).map { ($0.calendarIdentifier, $0.title) }
    }

    /// EKCalendar 색을 Nower 5테마 중 하나로 매핑. 실패 시 기본값.
    private static func themeColorName(for calendar: EKCalendar?) -> String {
        // Phase 1: 외부 일정 구분은 읽기전용 뱃지로 하므로 색은 단일 기본값.
        // 추후 calendar.cgColor → 최근접 테마 매핑으로 개선 예정.
        return "skyblue"
    }
    #endif
}
#endif
