//
//  Milestone.swift
//  NowerCore
//
//  마일스톤 — 서비스가 "너에 대해 하나 알아냈어" 하고 알리는, 드물게 '벌어낸' 순간.
//  매일 자기자랑하지 않는다(신뢰). 임계점을 처음 넘을 때만, 한 번.
//  "나를 알아간다"를 명시적으로 felt 하게 만드는 조각.
//
//  순수 함수. '이미 알린' 집합은 MilestoneStore(온디바이스)가 들고,
//  엔진은 도달 여부만 판단한다.
//

import Foundation

/// 학습 임계점
public enum Milestone: String, Sendable, Equatable, CaseIterable {
    /// 콜드스타트 탈출 — '평소'를 가늠할 만큼 개인 분포가 모임
    case personalBaseline
    /// 같은 요일 표본이 충분해져 요일 리듬이 보임
    case weekdayPattern
    /// 회고 보정이 실제 적용되기 시작(점수가 개인화됨)
    case calibrationActive

    public var id: String { rawValue }
}

public enum MilestoneEngine {

    /// 현재 데이터 상태에서 도달한 모든 마일스톤
    public static func allReached(comparison: DensityComparison, calibration: DensityCalibration) -> [Milestone] {
        var out: [Milestone] = []
        switch comparison.basis {
        case .coldStart: break
        case .recent: out.append(.personalBaseline)
        case .weekday: out.append(.personalBaseline); out.append(.weekdayPattern)
        }
        if calibration.isActive { out.append(.calibrationActive) }
        return out
    }

    /// 도달했지만 아직 안 알린 것 중 '가장 고급' 하나(없으면 nil).
    /// 우선순위: 보정 적용 > 요일 패턴 > 평소 학습.
    public static func newlyReached(
        comparison: DensityComparison,
        calibration: DensityCalibration,
        shown: Set<String>
    ) -> Milestone? {
        let reached = Set(allReached(comparison: comparison, calibration: calibration))
        for m in [Milestone.calibrationActive, .weekdayPattern, .personalBaseline]
        where reached.contains(m) && !shown.contains(m.id) {
            return m
        }
        return nil
    }
}

/// 마일스톤 카피 — 축하 한 줄(과하지 않게, 무엇을 알게 됐는지 구체적으로).
public enum MilestoneCopy {
    public static func text(_ m: Milestone) -> String {
        switch m {
        case .personalBaseline:
            return "이제 너의 ‘평소’를 알 만큼 기록이 모였어요. 오늘부터 평소와 견줘 짚어드릴게요."
        case .weekdayPattern:
            return "요일별 리듬이 보이기 시작했어요. 같은 요일끼리 견주면 더 정확해져요."
        case .calibrationActive:
            return "네 체감을 반영해, 점수를 너에게 맞추기 시작했어요."
        }
    }
}

/// '이미 알린' 마일스톤 집합 저장소 (UserDefaults 온디바이스).
public enum MilestoneStore {
    private static let key = "density.milestones.shown"

    public static func shownIDs(_ defaults: UserDefaults = .standard) -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    public static func markShown(_ ids: [String], _ defaults: UserDefaults = .standard) {
        guard !ids.isEmpty else { return }
        var s = shownIDs(defaults)
        s.formUnion(ids)
        defaults.set(Array(s), forKey: key)
    }
}
