//
//  DayReflection.swift
//  NowerCore
//
//  하루가 끝난 뒤 사용자가 남기는 "체감" 1탭 기록.
//  엔진이 예측한 밀도(predicted)와 실제 느낌(felt)의 간극을 모아
//  개인 보정(DensityCalibration)과 월간 리포트의 기분 분포에 쓴다.
//  순수 도메인 모델 — 저장/표현은 외부. 온디바이스 전제(민감 데이터 미전송).
//

import Foundation

/// 하루 체감 기록 한 건
public struct DayReflection: Identifiable, Codable, Sendable, Equatable {
    /// 기록 대상 날짜 (그 날의 자정 기준 권장)
    public let date: Date
    /// 사용자가 고른 체감 밴드 (여유/보통/과부하) — 1탭으로 선택
    public let feltBand: DensityBand
    /// 기록 시점에 엔진이 예측했던 점수(0~100). 보정 갭 계산에 사용.
    public let predictedScore: Int
    /// 기록 시점 예측 밴드 (예측 vs 체감 비교 표시용)
    public let predictedBand: DensityBand
    /// 선택 메모 (없으면 nil)
    public let note: String?
    /// 작성 시각
    public let createdAt: Date

    public var id: String { Self.dateKey(date) }

    public init(
        date: Date,
        feltBand: DensityBand,
        predictedScore: Int,
        predictedBand: DensityBand,
        note: String? = nil,
        createdAt: Date
    ) {
        self.date = date
        self.feltBand = feltBand
        self.predictedScore = predictedScore
        self.predictedBand = predictedBand
        self.note = note
        self.createdAt = createdAt
    }

    /// "yyyy-MM-dd" 날짜 키 (저장/조회 매칭용)
    public static func dateKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// 예측보다 더 힘들게(또는 덜) 느꼈는지 — 밴드 단계 차(체감 - 예측).
    /// +면 예측보다 무겁게 느낌, -면 가볍게 느낌.
    public var feltGapSteps: Int {
        feltBand.rank - predictedBand.rank
    }
}

public extension DensityBand {
    /// 밴드 서열 (여유 0 · 보통 1 · 과부하 2) — 비교/통계용
    var rank: Int {
        switch self {
        case .light: return 0
        case .moderate: return 1
        case .heavy: return 2
        }
    }

    /// 체감 밴드의 대표 점수(중앙값) — 보정 갭 계산에 사용
    var representativeScore: Int {
        switch self {
        case .light: return 17
        case .moderate: return 50
        case .heavy: return 83
        }
    }
}
