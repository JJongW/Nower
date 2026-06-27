//
//  MilestoneTests.swift
//  NowerCoreTests
//
//  마일스톤 엔진 검증 (순수 로직).
//

import XCTest
@testable import NowerCore

final class MilestoneTests: XCTestCase {

    private func comparison(_ basis: ComparisonBasis) -> DensityComparison {
        DensityComparison(todayScore: 60, relativeBand: .heavier, basis: basis,
                          sampleCount: 10, personalMedian: 40)
    }

    private let activeCalibration = DensityCalibration(offset: 8, sampleCount: 5)
    private let noCalibration = DensityCalibration.none

    // MARK: - 도달 판정

    func test_coldStart_noMilestones() {
        let reached = MilestoneEngine.allReached(comparison: comparison(.coldStart), calibration: noCalibration)
        XCTAssertTrue(reached.isEmpty)
    }

    func test_recent_reachesPersonalBaseline() {
        let reached = MilestoneEngine.allReached(comparison: comparison(.recent(days: 30)), calibration: noCalibration)
        XCTAssertEqual(reached, [.personalBaseline])
    }

    func test_weekday_reachesBaselineAndWeekday() {
        let reached = MilestoneEngine.allReached(comparison: comparison(.weekday("토")), calibration: noCalibration)
        XCTAssertTrue(reached.contains(.personalBaseline))
        XCTAssertTrue(reached.contains(.weekdayPattern))
    }

    func test_activeCalibration_addsCalibrationMilestone() {
        let reached = MilestoneEngine.allReached(comparison: comparison(.recent(days: 30)), calibration: activeCalibration)
        XCTAssertTrue(reached.contains(.calibrationActive))
    }

    // MARK: - newlyReached (안 알린 것 중 고급 우선)

    func test_newlyReached_returnsHighestUnshown() {
        // 보정 활성 + 요일패턴 도달, 아무것도 안 알림 → 보정이 우선
        let m = MilestoneEngine.newlyReached(
            comparison: comparison(.weekday("토")), calibration: activeCalibration, shown: [])
        XCTAssertEqual(m, .calibrationActive)
    }

    func test_newlyReached_skipsAlreadyShown() {
        // 보정·요일은 이미 알림 → 다음은 평소 학습
        let m = MilestoneEngine.newlyReached(
            comparison: comparison(.weekday("토")), calibration: activeCalibration,
            shown: ["calibrationActive", "weekdayPattern"])
        XCTAssertEqual(m, .personalBaseline)
    }

    func test_newlyReached_nilWhenAllShown() {
        let m = MilestoneEngine.newlyReached(
            comparison: comparison(.recent(days: 30)), calibration: noCalibration,
            shown: ["personalBaseline"])
        XCTAssertNil(m)
    }

    // MARK: - 저장소 (격리된 suite)

    func test_store_marksAndReads() {
        let suite = UserDefaults(suiteName: "milestone-test-\(UUID().uuidString)")!
        XCTAssertTrue(MilestoneStore.shownIDs(suite).isEmpty)
        MilestoneStore.markShown(["personalBaseline"], suite)
        XCTAssertEqual(MilestoneStore.shownIDs(suite), ["personalBaseline"])
    }
}
