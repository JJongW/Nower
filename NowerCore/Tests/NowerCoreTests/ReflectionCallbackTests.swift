//
//  ReflectionCallbackTests.swift
//  NowerCoreTests
//
//  체감 콜백 엔진 검증 (순수 로직).
//

import XCTest
@testable import NowerCore

final class ReflectionCallbackTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private let today: Date = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c.date(from: DateComponents(year: 2026, month: 6, day: 27))!
    }()

    private func daysAgo(_ n: Int) -> Date { calendar.date(byAdding: .day, value: -n, to: today)! }

    private func refl(_ n: Int, predicted: DensityBand, felt: DensityBand) -> DayReflection {
        DayReflection(date: daysAgo(n), feltBand: felt,
                      predictedScore: predicted.representativeScore, predictedBand: predicted,
                      note: nil, createdAt: daysAgo(n))
    }

    // MARK: - 발화

    func test_fires_whenSimilarDayFeltHeavy() {
        // 과거 '과부하 예측' 날을 '과부하'로 체감 → 오늘도 과부하면 콜백
        let refs = [refl(5, predicted: .heavy, felt: .heavy)]
        let c = ReflectionCallbackEngine.callback(todayBand: .heavy, reflections: refs, asOf: today, calendar: calendar)
        XCTAssertNotNil(c)
        XCTAssertTrue(c!.contains("버거"))
    }

    func test_pluralCount_whenMultipleMatches() {
        let refs = [refl(5, predicted: .heavy, felt: .heavy),
                    refl(12, predicted: .heavy, felt: .heavy),
                    refl(20, predicted: .heavy, felt: .heavy)]
        let c = ReflectionCallbackEngine.callback(todayBand: .heavy, reflections: refs, asOf: today, calendar: calendar)
        XCTAssertNotNil(c)
        XCTAssertTrue(c!.contains("3번"))
    }

    // MARK: - 비발화

    func test_noFire_onLightDay() {
        let refs = [refl(5, predicted: .heavy, felt: .heavy)]
        XCTAssertNil(ReflectionCallbackEngine.callback(todayBand: .light, reflections: refs, asOf: today, calendar: calendar))
    }

    func test_noFire_whenSimilarDayFeltFine() {
        // 같은 예측 밴드지만 '여유'로 체감했으면 콜백 없음
        let refs = [refl(5, predicted: .heavy, felt: .light)]
        XCTAssertNil(ReflectionCallbackEngine.callback(todayBand: .heavy, reflections: refs, asOf: today, calendar: calendar))
    }

    func test_noFire_whenDifferentBand() {
        // 과거 과부하 체감이지만 예측 밴드가 다르면(보통) 매칭 안 됨
        let refs = [refl(5, predicted: .moderate, felt: .heavy)]
        XCTAssertNil(ReflectionCallbackEngine.callback(todayBand: .heavy, reflections: refs, asOf: today, calendar: calendar))
    }

    func test_noFire_whenOutsideWindow() {
        let refs = [refl(200, predicted: .heavy, felt: .heavy)]
        XCTAssertNil(ReflectionCallbackEngine.callback(todayBand: .heavy, reflections: refs, asOf: today, calendar: calendar))
    }

    func test_excludesTodayItself() {
        // 오늘자 기록은 '과거'가 아니므로 제외
        let refs = [DayReflection(date: today, feltBand: .heavy, predictedScore: 83,
                                  predictedBand: .heavy, note: nil, createdAt: today)]
        XCTAssertNil(ReflectionCallbackEngine.callback(todayBand: .heavy, reflections: refs, asOf: today, calendar: calendar))
    }
}
