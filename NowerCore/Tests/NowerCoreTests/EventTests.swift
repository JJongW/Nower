//
//  EventTests.swift
//  NowerCoreTests
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import XCTest
@testable import NowerCore

final class EventTests: XCTestCase {

    // MARK: - Factory Method Tests

    func testAllDayEventCreation() {
        let date = Date()
        let event = Event.allDay(title: "휴가", date: date, colorTheme: .skyblue)

        XCTAssertEqual(event.title, "휴가")
        XCTAssertEqual(event.colorTheme, .skyblue)
        XCTAssertTrue(event.isAllDay)
        XCTAssertFalse(event.isMultiDay)
        XCTAssertEqual(event.durationInDays, 1)
    }

    func testAllDayPeriodEventCreation() {
        let calendar = Calendar.current
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: 3, to: startDate)!

        let event = Event.allDayPeriod(
            title: "출장",
            startDate: startDate,
            endDate: endDate,
            colorTheme: .peach
        )

        XCTAssertEqual(event.title, "출장")
        XCTAssertTrue(event.isAllDay)
        XCTAssertTrue(event.isMultiDay)
        XCTAssertEqual(event.durationInDays, 4) // 시작일 포함
    }

    func testTimedEventCreation() {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1시간 후

        let event = Event.timed(title: "미팅", start: start, end: end)

        XCTAssertEqual(event.title, "미팅")
        XCTAssertFalse(event.isAllDay)
        XCTAssertEqual(event.duration, 3600)
        XCTAssertEqual(event.durationInMinutes, 60)
    }

    func testTimedEventWithDurationCreation() {
        let start = Date()
        let event = Event.timed(title: "회의", start: start, durationMinutes: 90)

        XCTAssertEqual(event.durationInMinutes, 90)
    }

    // MARK: - Date Inclusion Tests

    func testSingleDayEventIncludesDate() {
        let today = Date()
        let event = Event.allDay(title: "오늘 일정", date: today)

        XCTAssertTrue(event.includesDate(today))

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        XCTAssertFalse(event.includesDate(tomorrow))
    }

    func testMultiDayEventIncludesDate() {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 2, to: startDate)!

        let event = Event.allDayPeriod(title: "3일 일정", startDate: startDate, endDate: endDate)

        XCTAssertTrue(event.includesDate(startDate))
        XCTAssertTrue(event.includesDate(calendar.date(byAdding: .day, value: 1, to: startDate)!))
        XCTAssertTrue(event.includesDate(endDate))

        let afterEnd = calendar.date(byAdding: .day, value: 3, to: startDate)!
        XCTAssertFalse(event.includesDate(afterEnd))
    }

    // MARK: - Update Tests

    func testEventUpdate() {
        let event = Event.allDay(title: "원래 제목", date: Date())
        let updated = event.updated(title: "새 제목", colorTheme: .lavender)

        XCTAssertEqual(updated.id, event.id) // ID 유지
        XCTAssertEqual(updated.title, "새 제목")
        XCTAssertEqual(updated.colorTheme, .lavender)
        XCTAssertEqual(updated.syncStatus, .pending) // 수정 시 pending
    }

    func testAddReminder() {
        let event = Event.allDay(title: "테스트", date: Date())
        XCTAssertTrue(event.reminders.isEmpty)

        let withReminder = event.addingReminder(.tenMinutesBefore)
        XCTAssertEqual(withReminder.reminders.count, 1)
        XCTAssertEqual(withReminder.reminders.first?.type, .minutesBefore)
        XCTAssertEqual(withReminder.reminders.first?.value, 10)
    }

    func testRemoveReminder() {
        let reminder = Reminder.thirtyMinutesBefore
        var event = Event.allDay(title: "테스트", date: Date())
        event = event.addingReminder(reminder)

        let withoutReminder = event.removingReminder(reminder)
        XCTAssertTrue(withoutReminder.reminders.isEmpty)
    }

    // MARK: - Codable Tests

    func testEventEncodingDecoding() throws {
        let original = Event.timed(
            title: "인코딩 테스트",
            start: Date(),
            durationMinutes: 60,
            colorTheme: .mintgreen
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Event.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.colorTheme, original.colorTheme)
        XCTAssertEqual(decoded.isAllDay, original.isAllDay)
    }

    // MARK: - Validation Tests

    func testValidEvent() {
        let event = Event.allDay(title: "유효한 일정", date: Date())
        XCTAssertTrue(event.isValid)
        XCTAssertTrue(event.validationErrors.isEmpty)
    }

    func testInvalidEventEmptyTitle() {
        let event = Event(
            title: "",
            startDateTime: Date(),
            endDateTime: Date()
        )

        XCTAssertFalse(event.isValid)
        XCTAssertTrue(event.validationErrors.contains { $0.contains("제목") })
    }

    func testInvalidEventEndBeforeStart() {
        let start = Date()
        let end = start.addingTimeInterval(-3600) // 1시간 전

        let event = Event(
            title: "잘못된 시간",
            startDateTime: start,
            endDateTime: end
        )

        XCTAssertFalse(event.isValid)
        XCTAssertTrue(event.validationErrors.contains { $0.contains("종료 시간") })
    }
}
