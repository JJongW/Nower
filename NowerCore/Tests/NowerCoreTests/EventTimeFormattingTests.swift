//
//  EventTimeFormattingTests.swift
//  NowerCoreTests
//
//  공유 시간 표기/매핑 로직 검증.
//

import XCTest
@testable import NowerCore

final class EventTimeFormattingTests: XCTestCase {

    // MARK: - parse

    func test_parse_valid() {
        XCTAssertEqual(EventTimeFormatting.parse(hhmm: "09:05"), ParsedTime(hour: 9, minute: 5))
        XCTAssertEqual(EventTimeFormatting.parse(hhmm: "23:59"), ParsedTime(hour: 23, minute: 59))
    }

    func test_parse_invalid() {
        XCTAssertNil(EventTimeFormatting.parse(hhmm: "24:00"))
        XCTAssertNil(EventTimeFormatting.parse(hhmm: "9:60"))
        XCTAssertNil(EventTimeFormatting.parse(hhmm: "abc"))
        XCTAssertNil(EventTimeFormatting.parse(hhmm: "9"))
    }

    // MARK: - displayKorean

    func test_display_morning_afternoon() {
        XCTAssertEqual(EventTimeFormatting.displayKorean(ParsedTime(hour: 9, minute: 0)), "오전 9:00")
        XCTAssertEqual(EventTimeFormatting.displayKorean(ParsedTime(hour: 13, minute: 30)), "오후 1:30")
    }

    func test_display_midnight_noon() {
        XCTAssertEqual(EventTimeFormatting.displayKorean(ParsedTime(hour: 0, minute: 0)), "오전 12:00")
        XCTAssertEqual(EventTimeFormatting.displayKorean(ParsedTime(hour: 12, minute: 0)), "오후 12:00")
    }

    func test_display_fromHHmm_fallback() {
        XCTAssertEqual(EventTimeFormatting.displayKorean(hhmm: "18:00"), "오후 6:00")
        XCTAssertEqual(EventTimeFormatting.displayKorean(hhmm: "garbage"), "garbage")
    }

    // MARK: - isEndAfterStart

    func test_endAfterStart() {
        XCTAssertEqual(EventTimeFormatting.isEndAfterStart(startHHmm: "11:00", endHHmm: "18:00"), true)
        XCTAssertEqual(EventTimeFormatting.isEndAfterStart(startHHmm: "18:00", endHHmm: "11:00"), false)
        XCTAssertEqual(EventTimeFormatting.isEndAfterStart(startHHmm: "11:00", endHHmm: "11:00"), false)
        XCTAssertNil(EventTimeFormatting.isEndAfterStart(startHHmm: nil, endHHmm: "18:00"))
    }

    // MARK: - EventFormInput

    func test_formInput_range() {
        let draft = ParsedEventDraft(
            title: "근무",
            startTime: ParsedTime(hour: 11, minute: 0),
            endTime: ParsedTime(hour: 18, minute: 0),
            isAllDay: false
        )
        let input = EventFormInput.from(draft: draft)
        XCTAssertEqual(input.title, "근무")
        XCTAssertEqual(input.startHHmm, "11:00")
        XCTAssertEqual(input.endHHmm, "18:00")
        XCTAssertFalse(input.isAllDay)
    }

    func test_formInput_normalizes_reversed() {
        let draft = ParsedEventDraft(
            startTime: ParsedTime(hour: 18, minute: 0),
            endTime: ParsedTime(hour: 11, minute: 0),
            isAllDay: false
        )
        let input = EventFormInput.from(draft: draft)
        XCTAssertEqual(input.startHHmm, "11:00")  // 역전 보정
        XCTAssertEqual(input.endHHmm, "18:00")
    }

    func test_formInput_dropsEndWithoutStart() {
        let draft = ParsedEventDraft(endTime: ParsedTime(hour: 10, minute: 0))
        let input = EventFormInput.from(draft: draft)
        XCTAssertNil(input.endHHmm)
        XCTAssertTrue(input.isAllDay)
    }
}
