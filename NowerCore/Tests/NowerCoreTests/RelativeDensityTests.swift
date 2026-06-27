//
//  RelativeDensityTests.swift
//  NowerCoreTests
//
//  자기 상대(self-relative) 표현 엔진 검증 (순수 로직).
//

import XCTest
@testable import NowerCore

final class RelativeDensityTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// 2026-06-27 (토요일) 기준
    private let today: Date = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c.date(from: DateComponents(year: 2026, month: 6, day: 27))!
    }()

    private func daysAgo(_ n: Int) -> Date {
        calendar.date(byAdding: .day, value: -n, to: today)!
    }

    /// 점수 분포(최근 10일, 10~70), 다양한 요일에 흩뿌림
    private func history10() -> [DailyScore] {
        [10, 20, 20, 30, 30, 40, 40, 50, 60, 70].enumerated().map {
            DailyScore(date: daysAgo($0.offset + 1), score: $0.element)
        }
    }

    // MARK: - 콜드스타트

    func test_coldStart_whenTooFewSamples() {
        let c = RelativeDensityEngine.compare(todayScore: 77, history: [], asOf: today, calendar: calendar)
        XCTAssertEqual(c.basis, .coldStart)
        XCTAssertEqual(c.sampleCount, 0)
        XCTAssertNil(c.personalMedian)
        // 콜드스타트 칩은 절대 밴드 라벨로 정직하게
        XCTAssertEqual(RelativeDensityCopy.chipLabel(c), DensityBand(score: 77).label)
    }

    func test_emptyDays_excludedFromBaseline() {
        // 활동일이 minSamples 미만이면(0점 날만 잔뜩) 콜드스타트로 떨어진다
        let zeros = (1...20).map { DailyScore(date: daysAgo($0), score: 0) }
        let c = RelativeDensityEngine.compare(todayScore: 50, history: zeros, asOf: today, calendar: calendar)
        XCTAssertEqual(c.basis, .coldStart)
    }

    // MARK: - 개인 30일 분포

    func test_personalDistribution_classifiesRelative() {
        let h = history10()
        let heavy = RelativeDensityEngine.compare(todayScore: 85, history: h, asOf: today, calendar: calendar)
        let light = RelativeDensityEngine.compare(todayScore: 12, history: h, asOf: today, calendar: calendar)
        let typ   = RelativeDensityEngine.compare(todayScore: 38, history: h, asOf: today, calendar: calendar)
        XCTAssertEqual(heavy.relativeBand, .heavier)
        XCTAssertEqual(light.relativeBand, .lighter)
        XCTAssertEqual(typ.relativeBand, .typical)
        XCTAssertEqual(heavy.basis, .recent(days: RelativeDensityEngine.windowDays))
    }

    // MARK: - 요일 보정

    func test_weekdayBasis_whenEnoughSameWeekdaySamples() {
        // today=토요일. 과거 토요일 4개를 낮은 점수로 추가 → 요일 분포로 보정
        var h = history10()
        for k in 1...4 {
            h.append(DailyScore(date: calendar.date(byAdding: .day, value: -7 * k, to: today)!, score: 15))
        }
        let c = RelativeDensityEngine.compare(todayScore: 50, history: h, asOf: today, calendar: calendar)
        if case .weekday = c.basis {} else { XCTFail("요일 보정이 적용돼야 함: \(c.basis)") }
        XCTAssertEqual(c.relativeBand, .heavier) // 평소 토요일(15)보다 50은 무거움
    }

    // MARK: - 통계 헬퍼

    func test_percentile_interpolates() {
        let s = [10, 20, 30, 40, 50]
        XCTAssertEqual(RelativeDensityEngine.median(s), 30)
        XCTAssertEqual(RelativeDensityEngine.percentile(s, 0.0), 10)
        XCTAssertEqual(RelativeDensityEngine.percentile(s, 1.0), 50)
    }

    // MARK: - 미래/오늘 제외

    func test_excludesTodayAndFuture() {
        var h = history10()
        h.append(DailyScore(date: today, score: 100))                                   // 오늘
        h.append(DailyScore(date: calendar.date(byAdding: .day, value: 1, to: today)!, score: 100)) // 미래
        let c = RelativeDensityEngine.compare(todayScore: 38, history: h, asOf: today, calendar: calendar)
        XCTAssertEqual(c.sampleCount, 10) // 오늘/미래는 분모에서 제외
    }
}
