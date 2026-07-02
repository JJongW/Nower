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
import CoreGraphics

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
            // .authorized는 iOS17에서 deprecated지만 일부 상태(시뮬레이터 grant 등)에서
            // 여전히 반환되므로 읽기 접근 가능으로 함께 인정한다.
            return status == .fullAccess || status == .authorized
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

    /// Nower 5테마 기준색(라이트 모드 RGB, AppColors와 동일). 최근접 매핑용.
    private static let themeReferenceColors: [(name: String, r: Double, g: Double, b: Double)] = [
        ("skyblue",   Double(0x73) / 255, Double(0xB3) / 255, Double(0xD9) / 255),
        ("peach",     Double(0xF2) / 255, Double(0xBF) / 255, Double(0x8C) / 255),
        ("lavender",  Double(0xB3) / 255, Double(0x99) / 255, Double(0xD9) / 255),
        ("mintgreen", Double(0x66) / 255, Double(0xB3) / 255, Double(0x99) / 255),
        ("coralred",  Double(0xF2) / 255, Double(0x8C) / 255, Double(0x80) / 255),
    ]

    /// EKCalendar 색을 Nower 5테마 중 최근접 색으로 매핑한다. 색을 못 읽으면 기본값(skyblue).
    private static func themeColorName(for calendar: EKCalendar?) -> String {
        guard let rgb = sRGBComponents(of: calendar?.cgColor) else { return "skyblue" }
        var best = "skyblue"
        var bestDistance = Double.greatestFiniteMagnitude
        for theme in themeReferenceColors {
            // sRGB 유클리드 거리(간이). 5개 버킷 분류엔 충분.
            let distance = pow(rgb.r - theme.r, 2) + pow(rgb.g - theme.g, 2) + pow(rgb.b - theme.b, 2)
            if distance < bestDistance {
                bestDistance = distance
                best = theme.name
            }
        }
        return best
    }

    /// CGColor를 sRGB 0...1 성분으로 변환. 색공간이 달라도 sRGB로 변환해 일관 비교.
    private static func sRGBComponents(of cgColor: CGColor?) -> (r: Double, g: Double, b: Double)? {
        guard let cgColor,
              let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = cgColor.converted(to: srgb, intent: .defaultIntent, options: nil),
              let comps = converted.components, comps.count >= 3 else {
            return nil
        }
        return (Double(comps[0]), Double(comps[1]), Double(comps[2]))
    }
    #endif
}
#endif
