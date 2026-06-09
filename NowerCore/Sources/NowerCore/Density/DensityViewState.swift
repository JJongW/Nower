//
//  DensityViewState.swift
//  NowerCore
//
//  DensityReport → 화면 표시용 표현 모델.
//  순수 매핑 — SwiftUI/AppKit 어디서나 같은 텍스트·색을 쓰도록.
//  색은 hex 문자열로 노출하고, 실제 Color 변환은 각 플랫폼 뷰에서.
//

import Foundation

/// 밀도 카드 한 장에 필요한 모든 표시 값
public struct DensityViewState: Sendable, Equatable {
    /// "72" 형태 점수 텍스트
    public let scoreText: String
    /// "여유/보통/과부하"
    public let bandLabel: String
    /// 밴드 색 hex (예: "#34C759")
    public let bandColorHex: String
    /// 0.0~1.0 진행률 (링/바 렌더용)
    public let progress: Double
    /// 점수 의미 한 줄
    public let meaning: String
    /// 자연어 narration 1~2줄 (raw 근거 인용)
    public let narration: String
    /// 행동 제안 문구 (없으면 nil)
    public let suggestion: String?
    /// 신호 분해 행 (기여 높은 순)
    public let signalRows: [SignalRow]

    /// 신호 분해 한 줄
    public struct SignalRow: Sendable, Equatable, Identifiable {
        public var id: String { signalKey }
        /// 신호 식별 키 (rawValue)
        public let signalKey: String
        /// 신호 라벨 ("전환" 등)
        public let label: String
        /// 근거 문구 ("이동 50분" 등)
        public let detail: String
        /// 0.0~1.0 강도 (바 길이)
        public let intensity: Double
    }

    public init(report: DensityReport) {
        self.scoreText = "\(report.score)"
        self.bandLabel = report.band.label
        self.bandColorHex = Self.colorHex(for: report.band)
        self.progress = Double(report.score) / 100.0
        self.meaning = report.meaning
        self.narration = report.narration
        self.suggestion = report.suggestion?.message
        self.signalRows = report.signals.map { signal in
            SignalRow(
                signalKey: signal.signal.rawValue,
                label: signal.signal.label,
                detail: signal.detail,
                intensity: signal.value
            )
        }
    }

    /// 밴드별 색 (Apple system 컬러 hex)
    static func colorHex(for band: DensityBand) -> String {
        band.colorHex
    }
}
