//
//  EventDraftParserTests.swift
//  NowerCoreTests
//
//  자연어 일정 파서 검증.
//

import XCTest
@testable import NowerCore

final class EventDraftParserTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// 기준일: 2026-06-10 (수요일)
    private var reference: Date {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 10
        return calendar.date(from: comps)!
    }

    private func parse(_ text: String) -> ParsedEventDraft {
        EventDraftParser.parse(text, referenceDate: reference, calendar: calendar)
    }

    private func dayOffset(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: reference))!
    }

    // MARK: - 핵심 케이스

    func test_내일_3시_회의() {
        let d = parse("내일 3시 회의")
        XCTAssertEqual(d.title, "회의")
        XCTAssertTrue(calendar.isDate(d.date!, inSameDayAs: dayOffset(1)))
        XCTAssertEqual(d.startTime, ParsedTime(hour: 15, minute: 0)) // 맨숫자 3 → 오후
        XCTAssertFalse(d.isAllDay)
        XCTAssertEqual(d.confidence, .high)
    }

    func test_오늘_종일_일정() {
        let d = parse("오늘 휴가")
        XCTAssertEqual(d.title, "휴가")
        XCTAssertTrue(calendar.isDate(d.date!, inSameDayAs: dayOffset(0)))
        XCTAssertTrue(d.isAllDay)
        XCTAssertNil(d.startTime)
        XCTAssertEqual(d.confidence, .medium)
    }

    func test_오후_2시부터_4시까지_미팅() {
        let d = parse("오후 2시부터 4시까지 미팅")
        XCTAssertEqual(d.title, "미팅")
        XCTAssertEqual(d.startTime, ParsedTime(hour: 14, minute: 0))
        XCTAssertEqual(d.endTime, ParsedTime(hour: 16, minute: 0))
        XCTAssertFalse(d.isAllDay)
    }

    func test_3시_반() {
        let d = parse("3시 반 미팅")
        XCTAssertEqual(d.startTime, ParsedTime(hour: 15, minute: 30))
    }

    func test_24시간_표기() {
        let d = parse("9:00 스탠드업")
        XCTAssertEqual(d.startTime, ParsedTime(hour: 9, minute: 0))
        XCTAssertEqual(d.title, "스탠드업")
    }

    func test_오전_명시() {
        let d = parse("오전 9시 조회")
        XCTAssertEqual(d.startTime, ParsedTime(hour: 9, minute: 0))
    }

    // MARK: - 반복

    func test_매주_월요일_운동() {
        let d = parse("매주 월요일 운동")
        XCTAssertEqual(d.title, "운동")
        XCTAssertNotNil(d.recurrenceRule)
        XCTAssertEqual(d.recurrenceRule?.frequency, .weekly)
        XCTAssertEqual(d.recurrenceRule?.daysOfWeek, [2]) // 월=2
    }

    func test_매일_반복() {
        let d = parse("매일 약먹기")
        XCTAssertEqual(d.title, "약먹기")
        XCTAssertEqual(d.recurrenceRule?.frequency, .daily)
    }

    // MARK: - 요일

    func test_다음주_금요일() {
        let d = parse("다음주 금요일 약속")
        XCTAssertEqual(d.title, "약속")
        // 금=6
        XCTAssertEqual(calendar.component(.weekday, from: d.date!), 6)
        XCTAssertGreaterThan(d.date!, reference)
    }

    // MARK: - 검증/보정

    func test_validation_endBeforeStart_normalized() {
        var draft = ParsedEventDraft(
            title: "회의",
            startTime: ParsedTime(hour: 16, minute: 0),
            endTime: ParsedTime(hour: 14, minute: 0),
            isAllDay: false
        )
        XCTAssertTrue(EventDraftValidation.issues(draft).contains(.endBeforeStart))
        draft = EventDraftValidation.normalized(draft)
        XCTAssertEqual(draft.startTime, ParsedTime(hour: 14, minute: 0))
        XCTAssertEqual(draft.endTime, ParsedTime(hour: 16, minute: 0))
    }

    func test_validation_endWithoutStart_dropped() {
        let draft = ParsedEventDraft(title: "x", endTime: ParsedTime(hour: 10, minute: 0))
        XCTAssertTrue(EventDraftValidation.issues(draft).contains(.endWithoutStart))
        XCTAssertNil(EventDraftValidation.normalized(draft).endTime)
    }

    func test_emptyInput_lowConfidence() {
        let d = parse("그냥 메모")
        XCTAssertNil(d.date)
        XCTAssertNil(d.startTime)
        XCTAssertEqual(d.confidence, .low)
    }

    func test_deterministic() {
        XCTAssertEqual(parse("내일 3시 회의"), parse("내일 3시 회의"))
    }
}
