//
//  ReminderTests.swift
//  NowerCoreTests
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import XCTest
@testable import NowerCore

final class ReminderTests: XCTestCase {

    // MARK: - Trigger Date Tests

    func testReminderAtTime() {
        let reminder = Reminder.atTime
        let eventStart = Date()

        let triggerDate = reminder.triggerDate(for: eventStart)

        XCTAssertEqual(triggerDate.timeIntervalSince1970, eventStart.timeIntervalSince1970, accuracy: 1)
    }

    func testReminderMinutesBefore() {
        let reminder = Reminder.fifteenMinutesBefore
        let eventStart = Date()

        let triggerDate = reminder.triggerDate(for: eventStart)
        let expectedTrigger = eventStart.addingTimeInterval(-15 * 60)

        XCTAssertEqual(triggerDate.timeIntervalSince1970, expectedTrigger.timeIntervalSince1970, accuracy: 1)
    }

    func testReminderHoursBefore() {
        let reminder = Reminder.oneHourBefore
        let eventStart = Date()

        let triggerDate = reminder.triggerDate(for: eventStart)
        let expectedTrigger = eventStart.addingTimeInterval(-60 * 60)

        XCTAssertEqual(triggerDate.timeIntervalSince1970, expectedTrigger.timeIntervalSince1970, accuracy: 1)
    }

    func testReminderDaysBefore() {
        let reminder = Reminder.oneDayBefore
        let eventStart = Date()

        let triggerDate = reminder.triggerDate(for: eventStart)
        let expectedTrigger = Calendar.current.date(byAdding: .day, value: -1, to: eventStart)!

        XCTAssertEqual(triggerDate.timeIntervalSince1970, expectedTrigger.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - Display String Tests

    func testReminderDisplayStrings() {
        XCTAssertEqual(Reminder.atTime.displayString, "정시 알림")
        XCTAssertEqual(Reminder.fiveMinutesBefore.displayString, "5분 전")
        XCTAssertEqual(Reminder.oneHourBefore.displayString, "1시간 전")
        XCTAssertEqual(Reminder.oneDayBefore.displayString, "1일 전")
    }

    // MARK: - Preset Tests

    func testReminderPresets() {
        let presets = Reminder.presets

        XCTAssertEqual(presets.count, 7)
        XCTAssertTrue(presets.contains { $0.type == .atTime })
        XCTAssertTrue(presets.contains { $0.type == .minutesBefore && $0.value == 5 })
        XCTAssertTrue(presets.contains { $0.type == .minutesBefore && $0.value == 10 })
        XCTAssertTrue(presets.contains { $0.type == .minutesBefore && $0.value == 15 })
        XCTAssertTrue(presets.contains { $0.type == .minutesBefore && $0.value == 30 })
        XCTAssertTrue(presets.contains { $0.type == .hoursBefore && $0.value == 1 })
        XCTAssertTrue(presets.contains { $0.type == .daysBefore && $0.value == 1 })
    }
}
