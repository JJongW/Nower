//
//  DensityReport.swift
//  NowerCore
//
//  하루 밀도 엔진의 출력 모델.
//  점수(0~100) + 밴드 + 신호별 분해 + 자연어 narration + 행동 제안.
//

import Foundation

/// 밀도를 구성하는 5개 신호
public enum DensitySignal: String, Sendable, CaseIterable {
    /// 전환 — 컨텍스트 스위치 횟수 (일정 개수 기반)
    case transitions
    /// 이동 부하 — 일정 간 이동 시간
    case travelLoad
    /// 사회 부하 — 대면 일정 수/연속
    case socialLoad
    /// 집중 분절 — 무중단 집중 블록 확보 정도
    case focusFragmentation
    /// 수면 충돌 — 어젯밤 수면 vs 오전 일정
    case sleepConflict
    /// 약속 부하 — 종일/기간 일정 건수 (시간 없는 커밋먼트)
    case commitmentLoad

    /// 사용자 표기용 라벨 (내부 분석어가 아니라 친화어 — UX 검토 반영)
    public var label: String {
        switch self {
        case .transitions: return "일정 전환"
        case .travelLoad: return "이동"
        case .socialLoad: return "사람 만나기"
        case .focusFragmentation: return "집중할 수 있는 시간"
        case .sleepConflict: return "수면"
        case .commitmentLoad: return "약속"
        }
    }
}

/// 신호 하나의 점수 분해
public struct SignalScore: Sendable, Equatable {
    public let signal: DensitySignal
    /// 신호 강도 0.0 ~ 1.0 (높을수록 부담)
    public let value: Double
    /// 합성에 쓰인 정규화 가중치 0.0 ~ 1.0
    public let weight: Double
    /// 분해 뷰에 보여줄 근거 문구 (예: "이동 50분")
    public let detail: String

    public init(signal: DensitySignal, value: Double, weight: Double, detail: String) {
        self.signal = signal
        self.value = value
        self.weight = weight
        self.detail = detail
    }

    /// 최종 점수 기여분 (value × weight)
    public var contribution: Double {
        value * weight
    }
}

/// 밀도 밴드 (색상 매핑)
public enum DensityBand: String, Sendable {
    case light      // 여유 (녹)
    case moderate   // 보통 (황)
    case heavy      // 과부하 (적)

    /// 0~100 점수에서 밴드 도출
    public init(score: Int) {
        switch score {
        case ..<34: self = .light
        case ..<67: self = .moderate
        default: self = .heavy
        }
    }

    public var label: String {
        switch self {
        case .light: return "여유"
        case .moderate: return "보통"
        case .heavy: return "과부하"
        }
    }

    /// 밴드 색 (Apple system 컬러 hex). 카드·칩·월 히트맵 공유.
    public var colorHex: String {
        switch self {
        case .light: return "#34C759"    // systemGreen
        case .moderate: return "#FF9500"  // systemOrange
        case .heavy: return "#FF3B30"     // systemRed
        }
    }
}

/// 채점 근거가 된 raw 측정값. narration·UI가 "왜 이 점수인지" 보여줄 때 사용.
public struct DensityMetrics: Sendable, Equatable {
    /// 시간 있는 일정 개수
    public let eventCount: Int
    /// 종일/기간 일정 개수
    public let allDayCount: Int
    /// 가장 긴 무중단 집중 블록(분)
    public let largestFocusBlockMinutes: Int
    /// 60분 미만 짧은 빈틈 개수
    public let smallGapCount: Int
    /// 가장 빡빡한 전환(가장 짧은 양수 빈틈, 분). 없으면 nil
    public let tightestGapMinutes: Int?
    /// 대면(위치 있는) 일정 수
    public let inPersonCount: Int
    /// 첫 일정 시작 시각(시 단위 실수, 예 9:50 → 9.83). 없으면 nil
    public let firstEventHour: Double?
    /// 총 이동 시간(분). 데이터 없으면 nil
    public let travelMinutes: Int?
    /// 어젯밤 수면 시간(시간). 데이터 없으면 nil
    public let sleepHours: Double?

    public init(
        eventCount: Int,
        allDayCount: Int,
        largestFocusBlockMinutes: Int,
        smallGapCount: Int,
        tightestGapMinutes: Int?,
        inPersonCount: Int,
        firstEventHour: Double?,
        travelMinutes: Int?,
        sleepHours: Double?
    ) {
        self.eventCount = eventCount
        self.allDayCount = allDayCount
        self.largestFocusBlockMinutes = largestFocusBlockMinutes
        self.smallGapCount = smallGapCount
        self.tightestGapMinutes = tightestGapMinutes
        self.inPersonCount = inPersonCount
        self.firstEventHour = firstEventHour
        self.travelMinutes = travelMinutes
        self.sleepHours = sleepHours
    }

    /// 빈 하루
    public static let empty = DensityMetrics(
        eventCount: 0, allDayCount: 0, largestFocusBlockMinutes: 0, smallGapCount: 0,
        tightestGapMinutes: nil, inPersonCount: 0, firstEventHour: nil,
        travelMinutes: nil, sleepHours: nil
    )
}

/// 채점 기준 앵커 — "보통 하루"를 정의하는 절대 기준치(v1).
/// narration이 raw값을 이 앵커와 비교해 의미를 만든다.
public enum DensityAnchor {
    /// 일정 개수: 이 이상이면 "많음"
    public static let busyEventCount = 5
    /// 권장 집중 블록(분)
    public static let recommendedFocusBlock = 90
    /// 짧은 빈틈: 이 이상이면 "잦은 끊김"
    public static let fragmentedGapCount = 3
    /// 이른 시작 기준 시각
    public static let earlyStartHour = 9.0
    /// 권장 최소 수면(시간)
    public static let recommendedSleepHours = 7.0
    /// 종일/기간 약속: 이 이상이면 "많음" (commitment 신호 포화 기준)
    public static let busyCommitmentCount = 3
}

/// 부담을 줄이는 단일 행동 제안
public struct ActionSuggestion: Sendable, Equatable {
    /// 어떤 신호를 줄이려는 제안인지
    public let signal: DensitySignal
    /// 사용자에게 보여줄 제안 문구
    public let message: String

    public init(signal: DensitySignal, message: String) {
        self.signal = signal
        self.message = message
    }
}

/// 하루 밀도 리포트 (엔진 최종 출력)
public struct DensityReport: Sendable {
    /// 0~100 밀도 점수
    public let score: Int
    /// 점수 밴드
    public let band: DensityBand
    /// 신호별 분해 (기여 높은 순)
    public let signals: [SignalScore]
    /// 이 밴드가 무슨 뜻인지 한 줄 (점수의 의미)
    public let meaning: String
    /// 자연어 narration 1~2줄 (raw 근거 인용)
    public let narration: String
    /// 행동 제안 1개 (없을 수도 있음)
    public let suggestion: ActionSuggestion?
    /// 채점 근거 raw 측정값
    public let metrics: DensityMetrics

    public init(
        score: Int,
        band: DensityBand,
        signals: [SignalScore],
        meaning: String,
        narration: String,
        suggestion: ActionSuggestion?,
        metrics: DensityMetrics
    ) {
        self.score = score
        self.band = band
        self.signals = signals
        self.meaning = meaning
        self.narration = narration
        self.suggestion = suggestion
        self.metrics = metrics
    }
}
