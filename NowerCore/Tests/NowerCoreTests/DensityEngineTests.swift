//
//  DensityEngineTests.swift
//  NowerCoreTests
//
//  하루 밀도 엔진 검증.
//

import XCTest
@testable import NowerCore

final class DensityEngineTests: XCTestCase {

    // 결정성 위해 UTC 고정 캘린더
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// 2026-06-09 기준 특정 시각 Date 생성
    private func date(_ hour: Int, _ minute: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 9
        comps.hour = hour; comps.minute = minute
        return calendar.date(from: comps)!
    }

    private var day: Date { date(0, 0) }

    private func timed(_ title: String, _ startHour: Int, _ durationMin: Int, location: Location? = nil) -> Event {
        let start = date(startHour, 0)
        return Event(
            title: title,
            startDateTime: start,
            endDateTime: start.addingTimeInterval(Double(durationMin) * 60),
            isAllDay: false,
            timeZone: calendar.timeZone,
            location: location
        )
    }

    private func input(_ events: [Event], sleep: SleepSummary? = nil, travel: [TravelLeg] = []) -> DensityInput {
        DensityInput(day: day, events: events, sleep: sleep, travel: travel, calendar: calendar)
    }

    // MARK: - 빈 하루

    func test_emptyDay_scoresZero() {
        let report = DensityEngine.score(input([]))
        XCTAssertEqual(report.score, 0)
        XCTAssertEqual(report.band, .light)
        XCTAssertTrue(report.signals.isEmpty)
        XCTAssertNil(report.suggestion)
    }

    func test_allDayEventsCountAsCommitment() {
        // 종일 일정만 있어도 '약속 부하'로 점수가 잡힌다 (0 아님)
        let allDay = Event.allDay(title: "휴가", date: day)
        let report = DensityEngine.score(input([allDay]))
        XCTAssertGreaterThan(report.score, 0)
        XCTAssertTrue(report.signals.contains { $0.signal == .commitmentLoad })
        XCTAssertEqual(report.metrics.allDayCount, 1)
    }

    // MARK: - 점유 기둥 / 역전 해소 (Phase 0)

    /// 핵심 회귀: 종일 todo 1개 < 8시간 시간 일정.
    /// (이전 채점식에선 종일 1개 27점 > 8시간 일정 8점으로 역전됐음)
    func test_fullTimedDay_outscoresSingleAllDay() {
        let allDayOnly = DensityEngine.score(input([Event.allDay(title: "운동하기", date: day)]))
        let fullDay = DensityEngine.score(input([
            timed("작업1", 10, 5 * 60),   // 10:00-15:00
            timed("작업2", 15, 3 * 60)    // 15:00-18:00
        ]))
        XCTAssertGreaterThan(fullDay.score, allDayOnly.score)
        XCTAssertEqual(allDayOnly.band, .light)        // 종일 1개는 여유
        XCTAssertGreaterThanOrEqual(fullDay.score, 50) // 8시간은 무거움
    }

    /// 점유 신호는 항상 포함되고, booked 분으로 raw 근거를 남긴다.
    func test_occupancySignal_alwaysPresent_andTracksBookedMinutes() {
        let report = DensityEngine.score(input([timed("A", 9, 120), timed("B", 14, 60)]))
        XCTAssertTrue(report.signals.contains { $0.signal == .occupancy })
        XCTAssertEqual(report.metrics.bookedMinutes, 180)
    }

    /// 겹치는 일정은 union으로 병합 — 이중 집계 안 함.
    func test_occupancy_mergesOverlap() {
        let report = DensityEngine.score(input([timed("A", 10, 120), timed("B", 11, 120)])) // 10-12, 11-13 → 10-13
        XCTAssertEqual(report.metrics.bookedMinutes, 180)
    }

    /// 위치 데이터가 전혀 없으면 사회 신호는 제외(graceful degrade) — 점수를 부당하게 깎지 않음.
    func test_noLocation_excludesSocialSignal() {
        let report = DensityEngine.score(input([timed("A", 10, 60), timed("B", 14, 60)]))
        XCTAssertFalse(report.signals.contains { $0.signal == .socialLoad })
    }

    func test_withLocation_includesSocialSignal() {
        let report = DensityEngine.score(input([
            timed("A", 10, 60, location: Location(name: "office")),
            timed("B", 14, 60)
        ]))
        XCTAssertTrue(report.signals.contains { $0.signal == .socialLoad })
    }

    // MARK: - 점수 단조성

    func test_moreEvents_higherScore() {
        let light = DensityEngine.score(input([timed("A", 10, 60)]))
        let heavy = DensityEngine.score(input([
            timed("A", 9, 30), timed("B", 10, 30), timed("C", 11, 30),
            timed("D", 13, 30), timed("E", 14, 30), timed("F", 16, 30)
        ]))
        XCTAssertGreaterThan(heavy.score, light.score)
    }

    func test_scoreInRange() {
        let report = DensityEngine.score(input([
            timed("A", 9, 30), timed("B", 10, 30), timed("C", 11, 30),
            timed("D", 13, 30), timed("E", 14, 30), timed("F", 16, 30),
            timed("G", 17, 30), timed("H", 18, 30)
        ]))
        XCTAssertGreaterThanOrEqual(report.score, 0)
        XCTAssertLessThanOrEqual(report.score, 100)
    }

    // MARK: - Graceful degrade (가중치 재정규화)

    func test_signalWeightsSumToOne() {
        let report = DensityEngine.score(input([timed("A", 10, 60), timed("B", 14, 60)]))
        let total = report.signals.reduce(0.0) { $0 + $1.weight }
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
    }

    func test_noSleepNoTravel_excludesThoseSignals() {
        let report = DensityEngine.score(input([timed("A", 10, 60)]))
        XCTAssertFalse(report.signals.contains { $0.signal == .sleepConflict })
        XCTAssertFalse(report.signals.contains { $0.signal == .travelLoad })
    }

    func test_withSleepAndTravel_includesSignals() {
        let a = timed("A", 9, 60, location: Location(name: "office"))
        let b = timed("B", 12, 60, location: Location(name: "cafe"))
        let report = DensityEngine.score(input(
            [a, b],
            sleep: SleepSummary(asleepDuration: 5 * 3600),
            travel: [TravelLeg(fromEventID: a.id, toEventID: b.id, travelTime: 40 * 60)]
        ))
        XCTAssertTrue(report.signals.contains { $0.signal == .sleepConflict })
        XCTAssertTrue(report.signals.contains { $0.signal == .travelLoad })
        // 가중치는 여전히 1로 정규화
        let total = report.signals.reduce(0.0) { $0 + $1.weight }
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
    }

    // MARK: - 수면 충돌

    func test_shortSleepEarlyStart_raisesSleepSignal() {
        let early = timed("새벽 회의", 6, 60)
        let report = DensityEngine.score(input(
            [early],
            sleep: SleepSummary(asleepDuration: 4 * 3600)
        ))
        let sleep = report.signals.first { $0.signal == .sleepConflict }
        XCTAssertNotNil(sleep)
        XCTAssertGreaterThan(sleep!.value, 0.5)
    }

    func test_fullSleepLateStart_lowSleepSignal() {
        let late = timed("점심 미팅", 13, 60)
        let report = DensityEngine.score(input(
            [late],
            sleep: SleepSummary(asleepDuration: 8 * 3600)
        ))
        let sleep = report.signals.first { $0.signal == .sleepConflict }
        XCTAssertNotNil(sleep)
        XCTAssertLessThan(sleep!.value, 0.2)
    }

    // MARK: - 이동 부하

    func test_travelLoad_scalesWithMinutes() {
        let a = timed("A", 9, 60)
        let b = timed("B", 12, 60)
        let little = DensityEngine.score(input([a, b],
            travel: [TravelLeg(fromEventID: a.id, toEventID: b.id, travelTime: 10 * 60)]))
        let lots = DensityEngine.score(input([a, b],
            travel: [TravelLeg(fromEventID: a.id, toEventID: b.id, travelTime: 120 * 60)]))
        let lv = little.signals.first { $0.signal == .travelLoad }!.value
        let hv = lots.signals.first { $0.signal == .travelLoad }!.value
        XCTAssertGreaterThan(hv, lv)
    }

    // MARK: - narration / 제안

    func test_narration_nonEmpty() {
        let report = DensityEngine.score(input([timed("A", 10, 60), timed("B", 11, 60)]))
        XCTAssertFalse(report.narration.isEmpty)
    }

    func test_heavyDay_producesSuggestion() {
        let a = timed("A", 9, 30, location: Location(name: "x"))
        let b = timed("B", 12, 30, location: Location(name: "y"))
        let report = DensityEngine.score(input([a, b],
            travel: [TravelLeg(fromEventID: a.id, toEventID: b.id, travelTime: 150 * 60)]))
        XCTAssertNotNil(report.suggestion)
    }

    // MARK: - 결정성

    func test_deterministic() {
        let events = [timed("A", 9, 30), timed("B", 11, 30), timed("C", 14, 30)]
        let r1 = DensityEngine.score(input(events))
        let r2 = DensityEngine.score(input(events))
        XCTAssertEqual(r1.score, r2.score)
        XCTAssertEqual(r1.narration, r2.narration)
    }

    // MARK: - ViewState 매핑

    func test_viewState_mapsScoreAndBand() {
        let report = DensityEngine.score(input([timed("A", 10, 60)]))
        let vs = DensityViewState(report: report)
        XCTAssertEqual(vs.scoreText, "\(report.score)")
        XCTAssertEqual(vs.bandLabel, report.band.label)
        XCTAssertEqual(vs.progress, Double(report.score) / 100.0, accuracy: 0.0001)
        XCTAssertEqual(vs.signalRows.count, report.signals.count)
    }

    func test_viewState_bandColors() {
        XCTAssertEqual(DensityViewState.colorHex(for: .light), "#34C759")
        XCTAssertEqual(DensityViewState.colorHex(for: .moderate), "#FF9500")
        XCTAssertEqual(DensityViewState.colorHex(for: .heavy), "#FF3B30")
    }

    // MARK: - 근거(metrics) / 의미 / 처방

    func test_metrics_eventCountMatchesTimedEvents() {
        let report = DensityEngine.score(input([
            timed("A", 9, 30), timed("B", 11, 30), timed("C", 14, 30)
        ]))
        XCTAssertEqual(report.metrics.eventCount, 3)
    }

    func test_metrics_largestFocusBlockComputed() {
        // 9:00-9:30, 그리고 14:00-14:30 → 사이 빈 블록 약 4.5시간(270분)
        let report = DensityEngine.score(input([timed("A", 9, 30), timed("B", 14, 30)]))
        XCTAssertGreaterThan(report.metrics.largestFocusBlockMinutes, 180)
    }

    func test_meaning_nonEmptyForAllBands() {
        let report = DensityEngine.score(input([timed("A", 10, 60)]))
        XCTAssertFalse(report.meaning.isEmpty)
    }

    func test_narration_citesEventCountForBusyDay() {
        let report = DensityEngine.score(input([
            timed("A", 9, 30), timed("B", 10, 30), timed("C", 11, 30),
            timed("D", 13, 30), timed("E", 14, 30), timed("F", 16, 30)
        ]))
        // 근거 narration에 일정 개수(6) 숫자가 인용돼야 함
        XCTAssertTrue(report.narration.contains("6"), "narration should cite raw count: \(report.narration)")
    }

    func test_emptyDay_hasEmptyMetrics() {
        let report = DensityEngine.score(input([]))
        XCTAssertEqual(report.metrics, DensityMetrics.empty)
    }

    func test_viewState_signalRowsSortedByContribution() {
        let report = DensityEngine.score(input([
            timed("A", 9, 30), timed("B", 10, 30), timed("C", 13, 30)
        ]))
        let vs = DensityViewState(report: report)
        // ViewState 행 순서 = report.signals 순서 (기여 내림차순)
        let reportKeys = report.signals.map { $0.signal.rawValue }
        XCTAssertEqual(vs.signalRows.map { $0.signalKey }, reportKeys)
    }
}
