//
//  ExternalCalendar.swift
//  NowerCore
//
//  외부 캘린더(Apple/Google/Naver) 읽기 전용 연동의 provider 중립 모델·프로토콜.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 외부 캘린더 소스 종류.
public enum CalendarSource: String, Codable, CaseIterable {
    case apple
    case google
    case naver
}

/// provider 중립 외부 이벤트 표현.
/// 반복 이벤트는 provider가 발생별로 이미 전개해서 넘겨준다(각 occurrence가 하나의 ExternalEvent).
public struct ExternalEvent: Hashable {
    public let source: CalendarSource
    /// 외부 원본 식별자. 반복 대비 유니크해야 함(예: eventIdentifier + occurrence start).
    public let externalID: String
    public let title: String
    public let start: Date
    public let end: Date?
    public let isAllDay: Bool
    /// 어느 외부 캘린더에서 왔는지(필터/뱃지용).
    public let calendarTitle: String
    /// 매핑된 테마 색 이름(provider가 결정). AppColors 테마명 중 하나.
    public let colorName: String

    public init(source: CalendarSource, externalID: String, title: String, start: Date, end: Date?, isAllDay: Bool, calendarTitle: String, colorName: String) {
        self.source = source
        self.externalID = externalID
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.calendarTitle = calendarTitle
        self.colorName = colorName
    }
}

extension ExternalEvent {
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// 외부 이벤트를 Nower의 읽기 전용 `TodoItem`으로 매핑한다.
    /// - 종일 단일: date 하나, scheduledTime nil
    /// - 종일 다일: startDate/endDate 기간
    /// - 시간 단일: date + scheduledTime/endScheduledTime
    /// - 시간 다일: startDate/endDate 기간 + 시작 시각
    /// 항상 `isRepeating=false`·`recurrenceInfo=nil`(이미 전개된 occurrence) → RecurringEventExpander를 타지 않음.
    public func toTodoItem() -> TodoItem {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        // 종일 이벤트의 EventKit end는 보통 마지막 순간이라, 표시상 하루를 빼서 포함 종료일을 구한다.
        let inclusiveEnd: Date = {
            guard let end = end else { return start }
            if isAllDay {
                // 종일: end가 자정이면 하루 전이 실제 마지막 날
                let endDay = calendar.startOfDay(for: end)
                if end == endDay, let prev = calendar.date(byAdding: .day, value: -1, to: endDay) {
                    return prev
                }
                return end
            }
            return end
        }()
        let endDay = calendar.startOfDay(for: inclusiveEnd)
        let isMultiDay = endDay > startDay

        let startDayStr = Self.dayFormatter.string(from: startDay)
        let commonID = UUID()

        if isAllDay {
            if isMultiDay {
                return TodoItem(id: commonID, text: title, isRepeating: false,
                                date: startDayStr, colorName: colorName,
                                startDate: startDayStr, endDate: Self.dayFormatter.string(from: endDay),
                                externalSource: source.rawValue, externalID: externalID)
            }
            return TodoItem(id: commonID, text: title, isRepeating: false,
                            date: startDayStr, colorName: colorName,
                            externalSource: source.rawValue, externalID: externalID)
        }

        // 시간 있는 이벤트
        let startTime = Self.timeFormatter.string(from: start)
        let endTime = end.map { Self.timeFormatter.string(from: $0) }

        if isMultiDay {
            return TodoItem(id: commonID, text: title, isRepeating: false,
                            date: startDayStr, colorName: colorName,
                            startDate: startDayStr, endDate: Self.dayFormatter.string(from: endDay),
                            scheduledTime: startTime, endScheduledTime: endTime,
                            externalSource: source.rawValue, externalID: externalID)
        }

        return TodoItem(id: commonID, text: title, isRepeating: false,
                        date: startDayStr, colorName: colorName,
                        scheduledTime: startTime, endScheduledTime: endTime,
                        externalSource: source.rawValue, externalID: externalID)
    }
}

/// 외부 캘린더 provider 추상화(읽기 전용).
public protocol CalendarProvider {
    var source: CalendarSource { get }
    /// 접근 권한을 요청/확인한다. 허용되면 true.
    func authorize() async -> Bool
    /// 주어진 기간의 이벤트를 가져온다(반복은 발생별 전개된 상태로).
    func fetchEvents(in range: DateInterval) async throws -> [ExternalEvent]
}
