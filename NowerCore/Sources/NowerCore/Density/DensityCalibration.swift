//
//  DensityCalibration.swift
//  NowerCore
//
//  "회고 보정 루프" — 사용자의 체감(DayReflection)과 엔진 예측의 누적 간극을
//  하나의 보정 오프셋으로 모아, 이후 예측 점수를 개인화한다.
//  범용 밀도 → "내" 밀도. 순수 함수(프라이버시 100%, 온디바이스).
//
//  원칙: 근거 없는 점수는 띄우지 않는다 — 보정이 적용되면 그 사실과
//  표본 수를 narration에 명시한다(블랙박스 금지).
//

import Foundation

/// 개인 밀도 보정값
public struct DensityCalibration: Sendable, Equatable {
    /// 예측 점수에 더할 보정 오프셋(점수 단위, 부호 있음). 0이면 보정 없음.
    public let offset: Int
    /// 보정에 쓰인 체감 기록 표본 수(최근 window 내)
    public let sampleCount: Int

    public init(offset: Int, sampleCount: Int) {
        self.offset = offset
        self.sampleCount = sampleCount
    }

    /// 보정 없음
    public static let none = DensityCalibration(offset: 0, sampleCount: 0)

    /// 표본이 충분하고 오프셋이 있어 실제로 적용 중인지
    public var isActive: Bool { sampleCount >= DensityCalibrator.minSamples && offset != 0 }
}

public enum DensityCalibrator {

    /// 보정을 켜기 위한 최소 체감 기록 수
    public static let minSamples = 3
    /// 보정 오프셋 한계(±) — 한쪽으로 과교정되지 않도록 클램프
    public static let maxOffset = 20
    /// 최근 며칠 분의 기록만 반영하는지(일)
    public static let windowDays = 21

    /// 체감 기록 모음 → 보정값.
    /// 각 기록의 (체감 대표점수 − 그때 예측점수) 평균을 오프셋으로 삼는다.
    public static func calibration(
        from reflections: [DayReflection],
        asOf now: Date,
        calendar: Calendar = .current
    ) -> DensityCalibration {
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: now) else {
            return .none
        }
        let recent = reflections.filter { $0.date >= windowStart && $0.date <= now }
        guard recent.count >= minSamples else { return .none }

        let gaps = recent.map { Double($0.feltBand.representativeScore - $0.predictedScore) }
        let avg = gaps.reduce(0, +) / Double(gaps.count)
        let clamped = max(-maxOffset, min(maxOffset, Int(avg.rounded())))
        return DensityCalibration(offset: clamped, sampleCount: recent.count)
    }

    /// 보정을 리포트에 적용 — 점수/밴드를 조정하고 narration에 근거 한 줄을 덧붙인다.
    /// 신호 분해·제안·metrics는 원본 유지(보정은 종합 점수에만 작용).
    public static func apply(_ report: DensityReport, calibration: DensityCalibration) -> DensityReport {
        guard calibration.isActive else { return report }

        let adjusted = max(0, min(100, report.score + calibration.offset))
        let newBand = DensityBand(score: adjusted)

        let sign = calibration.offset > 0 ? "+" : ""
        let note = "최근 체감 \(calibration.sampleCount)일을 반영해 \(sign)\(calibration.offset)점 보정했어요."
        let narration = report.narration.isEmpty ? note : report.narration + " " + note

        // 밴드가 바뀌면 의미 문장도 새 밴드에 맞춰 갱신
        let meaning = newBand == report.band
            ? report.meaning
            : NarrationBuilder.meaning(band: newBand, metrics: report.metrics)

        return DensityReport(
            score: adjusted,
            band: newBand,
            signals: report.signals,
            meaning: meaning,
            narration: narration,
            suggestion: report.suggestion,
            metrics: report.metrics
        )
    }
}
