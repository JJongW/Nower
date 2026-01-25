//
//  RecurrenceRuleTests.swift
//  NowerCoreTests
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import XCTest
@testable import NowerCore

final class RecurrenceRuleTests: XCTestCase {

    // MARK: - Daily Recurrence Tests

    func testDailyRecurrence() {
        let rule = RecurrenceRule.daily
        let startDate = Date()

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        XCTAssertNotNil(nextOccurrence)

        let expectedNext = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        XCTAssertEqual(nextOccurrence!.timeIntervalSince1970, expectedNext.timeIntervalSince1970, accuracy: 1)
    }

    func testDailyRecurrenceWithInterval() {
        let rule = RecurrenceRule(frequency: .daily, interval: 3)
        let startDate = Date()

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        XCTAssertNotNil(nextOccurrence)

        let expectedNext = Calendar.current.date(byAdding: .day, value: 3, to: startDate)!
        XCTAssertEqual(nextOccurrence!.timeIntervalSince1970, expectedNext.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - Weekly Recurrence Tests

    func testWeeklyRecurrence() {
        let rule = RecurrenceRule.weekly
        let startDate = Date()

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        XCTAssertNotNil(nextOccurrence)

        let expectedNext = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startDate)!
        XCTAssertEqual(nextOccurrence!.timeIntervalSince1970, expectedNext.timeIntervalSince1970, accuracy: 1)
    }

    func testWeekdaysRecurrence() {
        let rule = RecurrenceRule.weekdays // 월-금

        // 주어진 날짜부터 다음 평일 찾기
        let calendar = Calendar.current
        var testDate = Date()

        // 다음 발생 확인
        if let nextOccurrence = rule.nextOccurrence(after: testDate) {
            let weekday = calendar.component(.weekday, from: nextOccurrence)
            // 2 = 월요일, 6 = 금요일 (1 = 일요일, 7 = 토요일)
            XCTAssertTrue((2...6).contains(weekday), "평일이어야 함: \(weekday)")
        }
    }

    // MARK: - Monthly Recurrence Tests

    func testMonthlyRecurrence() {
        let rule = RecurrenceRule.monthly
        let startDate = Date()

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        XCTAssertNotNil(nextOccurrence)

        let expectedNext = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        XCTAssertEqual(nextOccurrence!.timeIntervalSince1970, expectedNext.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - Yearly Recurrence Tests

    func testYearlyRecurrence() {
        let rule = RecurrenceRule.yearly
        let startDate = Date()

        let nextOccurrence = rule.nextOccurrence(after: startDate)
        XCTAssertNotNil(nextOccurrence)

        let expectedNext = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        XCTAssertEqual(nextOccurrence!.timeIntervalSince1970, expectedNext.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - End Date Tests

    func testRecurrenceWithEndDate() {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 5, to: Date())!

        let rule = RecurrenceRule(frequency: .daily, endDate: endDate)

        // 종료일 이전: 다음 발생 있음
        let beforeEnd = calendar.date(byAdding: .day, value: 3, to: Date())!
        let nextBefore = rule.nextOccurrence(after: beforeEnd)
        XCTAssertNotNil(nextBefore)

        // 종료일 이후: 다음 발생 없음
        let afterEnd = calendar.date(byAdding: .day, value: 6, to: Date())!
        let nextAfter = rule.nextOccurrence(after: afterEnd)
        XCTAssertNil(nextAfter)
    }

    // MARK: - Occurrences Tests

    func testOccurrencesInRange() {
        let rule = RecurrenceRule.daily
        let calendar = Calendar.current
        let start = Date()
        let end = calendar.date(byAdding: .day, value: 10, to: start)!

        let occurrences = rule.occurrences(from: start, to: end)

        XCTAssertEqual(occurrences.count, 10)
    }

    func testOccurrencesWithLimit() {
        let rule = RecurrenceRule.daily
        let calendar = Calendar.current
        let start = Date()
        let end = calendar.date(byAdding: .day, value: 100, to: start)!

        let occurrences = rule.occurrences(from: start, to: end, limit: 5)

        XCTAssertEqual(occurrences.count, 5)
    }

    // MARK: - Display String Tests

    func testDisplayStrings() {
        XCTAssertEqual(RecurrenceRule.daily.displayString, "매일")
        XCTAssertEqual(RecurrenceRule.weekly.displayString, "매주")
        XCTAssertEqual(RecurrenceRule.monthly.displayString, "매월")
        XCTAssertEqual(RecurrenceRule.yearly.displayString, "매년")

        let biweekly = RecurrenceRule(frequency: .weekly, interval: 2)
        XCTAssertEqual(biweekly.displayString, "2주마다")
    }
}
