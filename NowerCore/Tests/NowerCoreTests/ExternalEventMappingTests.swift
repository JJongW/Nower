//
//  ExternalEventMappingTests.swift
//  NowerCoreTests
//
//  외부 캘린더 이벤트 → TodoItem 매핑 검증 (순수 로직).
//

import XCTest
@testable import NowerCore

final class ExternalEventMappingTests: XCTestCase {

    // 매핑은 Calendar.current/기본 타임존을 쓰므로, 입력도 동일 기준으로 만들어 자기일관성 유지.
    private let calendar = Calendar.current

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d; comps.hour = h; comps.minute = min
        return calendar.date(from: comps)!
    }

    private func event(start: Date, end: Date?, isAllDay: Bool) -> ExternalEvent {
        ExternalEvent(source: .apple, externalID: "evt-1", title: "회의",
                      start: start, end: end, isAllDay: isAllDay,
                      calendarTitle: "Work", colorName: "skyblue")
    }

    // 공통: 외부 필드가 항상 세팅되고 비반복이어야 함
    private func assertExternalInvariants(_ todo: TodoItem) {
        XCTAssertEqual(todo.externalSource, "apple")
        XCTAssertEqual(todo.externalID, "evt-1")
        XCTAssertTrue(todo.isExternal)
        XCTAssertTrue(todo.isReadOnly)
        XCTAssertFalse(todo.isRepeating)
        XCTAssertNil(todo.recurrenceInfo)
        XCTAssertEqual(todo.text, "회의")
    }

    func testAllDaySingle() {
        // 종일 단일: EventKit end는 다음날 자정
        let todo = event(start: date(2026, 7, 1), end: date(2026, 7, 2), isAllDay: true).toTodoItem()
        assertExternalInvariants(todo)
        XCTAssertFalse(todo.isPeriodEvent)
        XCTAssertEqual(todo.date, "2026-07-01")
        XCTAssertNil(todo.scheduledTime)
    }

    func testAllDayMultiDay() {
        // 종일 3일(1~3일): EventKit end는 4일 자정 → 포함 종료일 3일
        let todo = event(start: date(2026, 7, 1), end: date(2026, 7, 4), isAllDay: true).toTodoItem()
        assertExternalInvariants(todo)
        XCTAssertTrue(todo.isPeriodEvent)
        XCTAssertEqual(todo.startDate, "2026-07-01")
        XCTAssertEqual(todo.endDate, "2026-07-03")
        XCTAssertNil(todo.scheduledTime)
    }

    func testTimedSingleDay() {
        let todo = event(start: date(2026, 7, 1, 9, 0), end: date(2026, 7, 1, 10, 30), isAllDay: false).toTodoItem()
        assertExternalInvariants(todo)
        XCTAssertFalse(todo.isPeriodEvent)
        XCTAssertEqual(todo.date, "2026-07-01")
        XCTAssertEqual(todo.scheduledTime, "09:00")
        XCTAssertEqual(todo.endScheduledTime, "10:30")
    }

    func testTimedMultiDay() {
        // 자정을 넘기는 시간 일정 (1일 22:00 ~ 2일 01:00)
        let todo = event(start: date(2026, 7, 1, 22, 0), end: date(2026, 7, 2, 1, 0), isAllDay: false).toTodoItem()
        assertExternalInvariants(todo)
        XCTAssertTrue(todo.isPeriodEvent)
        XCTAssertEqual(todo.startDate, "2026-07-01")
        XCTAssertEqual(todo.endDate, "2026-07-02")
        XCTAssertEqual(todo.scheduledTime, "22:00")
        XCTAssertEqual(todo.endScheduledTime, "01:00")
    }

    func testIncludesDateForMappedPeriod() {
        // 매핑된 기간 일정이 중간 날짜를 포함하는지 (todos(for:) 병합 정합성)
        let todo = event(start: date(2026, 7, 1), end: date(2026, 7, 4), isAllDay: true).toTodoItem()
        XCTAssertTrue(todo.includesDate(date(2026, 7, 2)))
        XCTAssertFalse(todo.includesDate(date(2026, 7, 4)))
    }
}
