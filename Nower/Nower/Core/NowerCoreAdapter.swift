//
//  NowerCoreAdapter.swift
//  Nower (macOS)
//
//  NowerCore와 레거시 타입 간의 변환 어댑터
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

#if canImport(NowerCore)
import NowerCore

// MARK: - Type Aliases for Gradual Migration

/// NowerCore의 Event를 앱에서 직접 사용할 수 있도록 타입 별칭 제공
public typealias NEvent = NowerCore.Event
public typealias NReminder = NowerCore.Reminder
public typealias NRecurrenceRule = NowerCore.RecurrenceRule
public typealias NLocation = NowerCore.Location
public typealias NColorTheme = NowerCore.ColorTheme
public typealias NSyncStatus = NowerCore.SyncStatus
public typealias NCalendarDay = NowerCore.CalendarDay
public typealias NWeekDayInfo = NowerCore.WeekDayInfo

// MARK: - TodoItem ↔ Event Conversion

extension TodoItem {
    /// TodoItem을 NowerCore Event로 변환
    func toEvent() -> NowerCore.Event {
        let startDate: Date
        let endDate: Date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if isPeriodEvent,
           let startStr = self.startDate,
           let endStr = self.endDate,
           let start = formatter.date(from: startStr),
           let end = formatter.date(from: endStr) {
            startDate = Calendar.current.startOfDay(for: start)
            var endComponents = DateComponents()
            endComponents.day = 1
            endComponents.second = -1
            endDate = Calendar.current.date(byAdding: endComponents, to: Calendar.current.startOfDay(for: end)) ?? end
        } else if let date = formatter.date(from: self.date) {
            startDate = Calendar.current.startOfDay(for: date)
            var endComponents = DateComponents()
            endComponents.day = 1
            endComponents.second = -1
            endDate = Calendar.current.date(byAdding: endComponents, to: startDate) ?? startDate
        } else {
            startDate = Date()
            endDate = startDate
        }

        let recurrenceRule: NowerCore.RecurrenceRule? = isRepeating ? .daily : nil

        return NowerCore.Event(
            id: id,
            title: text,
            colorTheme: NowerCore.ColorTheme.from(legacyColorName: colorName),
            startDateTime: startDate,
            endDateTime: endDate,
            isAllDay: true,
            timeZone: .current,
            recurrenceRule: recurrenceRule,
            reminders: [],
            createdAt: Date(),
            modifiedAt: Date(),
            syncStatus: .synced,
            location: nil,
            notes: nil,
            url: nil
        )
    }
}

extension NowerCore.Event {
    /// NowerCore Event를 TodoItem으로 변환 (레거시 호환성)
    func toTodoItem() -> TodoItem {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let dateString = formatter.string(from: startDateTime)

        if isMultiDay {
            return TodoItem(
                id: id,
                text: title,
                isRepeating: isRecurring,
                date: dateString,
                colorName: colorTheme.rawValue,
                startDate: formatter.string(from: startDateTime),
                endDate: formatter.string(from: endDateTime)
            )
        } else {
            return TodoItem(
                id: id,
                text: title,
                isRepeating: isRecurring,
                date: dateString,
                colorName: colorTheme.rawValue,
                startDate: nil,
                endDate: nil
            )
        }
    }
}

// MARK: - Array Conversion Helpers

extension Array where Element == TodoItem {
    /// TodoItem 배열을 Event 배열로 변환
    func toEvents() -> [NowerCore.Event] {
        map { $0.toEvent() }
    }
}

extension Array where Element == NowerCore.Event {
    /// Event 배열을 TodoItem 배열로 변환
    func toTodoItems() -> [TodoItem] {
        map { $0.toTodoItem() }
    }
}

// MARK: - CalendarDay Conversion

extension NowerCore.CalendarDay {
    /// NowerCore CalendarDay의 이벤트를 TodoItem으로 변환
    var todoItems: [TodoItem] {
        events.toTodoItems()
    }
}

// MARK: - Date Helpers from NowerCore

public extension Date {
    /// NowerCore의 Date 확장 사용
    var nowerDateString: String {
        toDateString()
    }

    var nowerTimeString: String {
        toTimeString()
    }

    var nowerKoreanDate: String {
        toKoreanDateString()
    }
}

#else

// MARK: - Stub when NowerCore is not available

/// NowerCore 패키지가 연결되지 않았을 때의 플레이스홀더
/// Xcode에서 NowerCore 패키지를 추가한 후 이 코드는 사용되지 않습니다.
enum NowerCoreNotLinked {
    static func warning() {
        print("⚠️ NowerCore 패키지가 연결되지 않았습니다. Xcode에서 패키지를 추가해주세요.")
    }
}

#endif
