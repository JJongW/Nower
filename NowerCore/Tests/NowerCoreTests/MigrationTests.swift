//
//  MigrationTests.swift
//  NowerCoreTests
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import XCTest
@testable import NowerCore

final class MigrationTests: XCTestCase {

    // MARK: - LegacyTodoItem Migration Tests

    func testMigrateSingleDayEvent() {
        let legacy = LegacyTodoItem(
            text: "테스트 일정",
            isRepeating: false,
            date: "2025-01-25",
            colorName: "skyblue"
        )

        let event = EventMigrator.migrate(from: legacy)

        XCTAssertEqual(event.id, legacy.id)
        XCTAssertEqual(event.title, "테스트 일정")
        XCTAssertEqual(event.colorTheme, .skyblue)
        XCTAssertTrue(event.isAllDay)
        XCTAssertFalse(event.isMultiDay)
        XCTAssertNil(event.recurrenceRule)
    }

    func testMigratePeriodEvent() {
        let legacy = LegacyTodoItem(
            text: "출장",
            isRepeating: false,
            date: "2025-01-20",
            colorName: "peach",
            startDate: "2025-01-20",
            endDate: "2025-01-23"
        )

        let event = EventMigrator.migrate(from: legacy)

        XCTAssertEqual(event.title, "출장")
        XCTAssertEqual(event.colorTheme, .peach)
        XCTAssertTrue(event.isAllDay)
        XCTAssertTrue(event.isMultiDay)
        XCTAssertEqual(event.durationInDays, 4)
    }

    func testMigrateRepeatingEvent() {
        let legacy = LegacyTodoItem(
            text: "매일 운동",
            isRepeating: true,
            date: "2025-01-25",
            colorName: "mintgreen"
        )

        let event = EventMigrator.migrate(from: legacy)

        XCTAssertEqual(event.title, "매일 운동")
        XCTAssertNotNil(event.recurrenceRule)
        XCTAssertEqual(event.recurrenceRule?.frequency, .daily)
    }

    func testMigrateUnknownColor() {
        let legacy = LegacyTodoItem(
            text: "알 수 없는 색상",
            isRepeating: false,
            date: "2025-01-25",
            colorName: "unknown_color"
        )

        let event = EventMigrator.migrate(from: legacy)

        XCTAssertEqual(event.colorTheme, .skyblue) // 기본값
    }

    func testMigrateBatchEvents() {
        let legacyItems = [
            LegacyTodoItem(text: "일정1", isRepeating: false, date: "2025-01-25", colorName: "skyblue"),
            LegacyTodoItem(text: "일정2", isRepeating: true, date: "2025-01-26", colorName: "peach"),
            LegacyTodoItem(text: "일정3", isRepeating: false, date: "2025-01-27", colorName: "lavender"),
        ]

        let events = EventMigrator.migrate(from: legacyItems)

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0].title, "일정1")
        XCTAssertEqual(events[1].title, "일정2")
        XCTAssertEqual(events[2].title, "일정3")
    }

    // MARK: - LegacyTodoItem Tests

    func testLegacyTodoItemIsPeriodEvent() {
        let singleDay = LegacyTodoItem(
            text: "단일",
            isRepeating: false,
            date: "2025-01-25",
            colorName: "skyblue"
        )

        let periodEvent = LegacyTodoItem(
            text: "기간",
            isRepeating: false,
            date: "2025-01-25",
            colorName: "skyblue",
            startDate: "2025-01-25",
            endDate: "2025-01-27"
        )

        XCTAssertFalse(singleDay.isPeriodEvent)
        XCTAssertTrue(singleDay.isSingleDayEvent)
        XCTAssertTrue(periodEvent.isPeriodEvent)
        XCTAssertFalse(periodEvent.isSingleDayEvent)
    }

    func testLegacyTodoItemDuration() {
        let singleDay = LegacyTodoItem(
            text: "단일",
            isRepeating: false,
            date: "2025-01-25",
            colorName: "skyblue"
        )

        let periodEvent = LegacyTodoItem(
            text: "기간",
            isRepeating: false,
            date: "2025-01-25",
            colorName: "skyblue",
            startDate: "2025-01-25",
            endDate: "2025-01-28"
        )

        XCTAssertEqual(singleDay.durationInDays, 1)
        XCTAssertEqual(periodEvent.durationInDays, 4)
    }

    func testLegacyTodoItemIncludesDate() {
        let periodEvent = LegacyTodoItem(
            text: "기간",
            isRepeating: false,
            date: "2025-01-25",
            colorName: "skyblue",
            startDate: "2025-01-25",
            endDate: "2025-01-27"
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let jan25 = formatter.date(from: "2025-01-25")!
        let jan26 = formatter.date(from: "2025-01-26")!
        let jan27 = formatter.date(from: "2025-01-27")!
        let jan28 = formatter.date(from: "2025-01-28")!

        XCTAssertTrue(periodEvent.includesDate(jan25))
        XCTAssertTrue(periodEvent.includesDate(jan26))
        XCTAssertTrue(periodEvent.includesDate(jan27))
        XCTAssertFalse(periodEvent.includesDate(jan28))
    }
}
