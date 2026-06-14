//
//  DensityCalibrationTests.swift
//  NowerCoreTests
//
//  회고 보정 루프 + 월간 에너지 리포트 검증 (순수 로직).
//

import XCTest
@testable import NowerCore

final class DensityCalibrationTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return calendar.date(from: comps)!
    }

    private func reflection(_ d: Date, felt: DensityBand, predicted: Int) -> DayReflection {
        DayReflection(
            date: d,
            feltBand: felt,
            predictedScore: predicted,
            predictedBand: DensityBand(score: predicted),
            note: nil,
            createdAt: d
        )
    }

    // MARK: - Calibration

    func test_calibration_belowMinSamples_isNone() {
        let asOf = date(2026, 6, 20)
        let refs = [
            reflection(date(2026, 6, 18), felt: .heavy, predicted: 20),
            reflection(date(2026, 6, 19), felt: .heavy, predicted: 20),
        ]
        let cal = DensityCalibrator.calibration(from: refs, asOf: asOf, calendar: calendar)
        XCTAssertFalse(cal.isActive)
        XCTAssertEqual(cal.offset, 0)
    }

    func test_calibration_feltHeavierThanPredicted_positiveOffsetClamped() {
        let asOf = date(2026, 6, 20)
        // 예측 20(여유)인데 매번 과부하(대표 83)로 느낌 → 갭 +63 → ±20으로 클램프
        let refs = [
            reflection(date(2026, 6, 16), felt: .heavy, predicted: 20),
            reflection(date(2026, 6, 17), felt: .heavy, predicted: 20),
            reflection(date(2026, 6, 18), felt: .heavy, predicted: 20),
        ]
        let cal = DensityCalibrator.calibration(from: refs, asOf: asOf, calendar: calendar)
        XCTAssertTrue(cal.isActive)
        XCTAssertEqual(cal.sampleCount, 3)
        XCTAssertEqual(cal.offset, DensityCalibrator.maxOffset)
    }

    func test_calibration_ignoresReflectionsOutsideWindow() {
        let asOf = date(2026, 6, 20)
        // 21일 윈도우 밖(5월) 2건 + 안쪽 1건 → 표본 부족
        let refs = [
            reflection(date(2026, 5, 1), felt: .heavy, predicted: 20),
            reflection(date(2026, 5, 2), felt: .heavy, predicted: 20),
            reflection(date(2026, 6, 19), felt: .heavy, predicted: 20),
        ]
        let cal = DensityCalibrator.calibration(from: refs, asOf: asOf, calendar: calendar)
        XCTAssertFalse(cal.isActive)
    }

    func test_apply_shiftsScoreAndBand_andAnnotatesNarration() {
        let base = DensityReport(
            score: 40, band: .moderate, signals: [],
            meaning: "기준 의미", narration: "기준 근거.",
            suggestion: nil, metrics: .empty
        )
        let cal = DensityCalibration(offset: 20, sampleCount: 4)
        let out = DensityCalibrator.apply(base, calibration: cal)
        XCTAssertEqual(out.score, 60)
        XCTAssertEqual(out.band, .moderate)        // 40→60 둘 다 moderate
        XCTAssertTrue(out.narration.contains("보정"))
        XCTAssertTrue(out.narration.contains("기준 근거"))
    }

    func test_apply_inactiveCalibration_returnsUnchanged() {
        let base = DensityReport(
            score: 40, band: .moderate, signals: [],
            meaning: "m", narration: "n", suggestion: nil, metrics: .empty
        )
        let out = DensityCalibrator.apply(base, calibration: .none)
        XCTAssertEqual(out.score, 40)
        XCTAssertEqual(out.narration, "n")
    }

    // MARK: - Monthly Energy Report

    private func emptyMonth(heavy: Int = 0, moderate: Int = 0, light: Int = 0,
                            busiestWeekday: Int? = nil, heaviest: DayDensity? = nil) -> MonthDensityReport {
        MonthDensityReport(
            days: [], heavyCount: heavy, moderateCount: moderate, lightCount: light,
            heaviestDay: heaviest, weekdayAverages: [:], busiestWeekday: busiestWeekday,
            narration: ""
        )
    }

    func test_monthlyReport_aggregatesFeltDistributionAndGaps() {
        let density = emptyMonth(heavy: 3, moderate: 5, light: 2, busiestWeekday: 5)
        let refs = [
            reflection(date(2026, 6, 2), felt: .heavy, predicted: 20),   // heavier
            reflection(date(2026, 6, 3), felt: .heavy, predicted: 20),   // heavier
            reflection(date(2026, 6, 4), felt: .light, predicted: 80),   // lighter
            reflection(date(2026, 7, 1), felt: .heavy, predicted: 20),   // 다른 달 → 제외
        ]
        let report = MonthlyEnergyReportEngine.make(
            month: date(2026, 6, 15),
            density: density,
            reflections: refs,
            calibration: .none,
            calendar: calendar
        )
        XCTAssertEqual(report.felt.total, 3)           // 6월 3건만
        XCTAssertEqual(report.felt.heavy, 2)
        XCTAssertEqual(report.felt.light, 1)
        XCTAssertEqual(report.heavierThanExpectedDays, 2)
        XCTAssertEqual(report.lighterThanExpectedDays, 1)
        XCTAssertFalse(report.narration.isEmpty)
    }

    func test_monthlyReport_prescription_clusteredOverloadSuggestsSpread() {
        let density = emptyMonth(heavy: 3, moderate: 2, light: 1, busiestWeekday: 5) // 목요일
        let report = MonthlyEnergyReportEngine.make(
            month: date(2026, 6, 15), density: density,
            reflections: [], calibration: .none, calendar: calendar
        )
        XCTAssertNotNil(report.prescription)
        XCTAssertTrue(report.prescription!.contains("목요일"))
    }

    func test_monthlyReport_calmMonth_positivePrescription() {
        let density = emptyMonth(heavy: 0, moderate: 2, light: 3)
        let report = MonthlyEnergyReportEngine.make(
            month: date(2026, 6, 15), density: density,
            reflections: [], calibration: .none, calendar: calendar
        )
        XCTAssertNotNil(report.prescription)
    }
}
