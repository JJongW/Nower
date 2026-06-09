//
//  DensityInput.swift
//  NowerCore
//
//  하루 밀도(Day Density) 엔진의 입력 모델.
//  플랫폼(iOS/macOS) 어댑터가 EventKit·HealthKit·MapKit에서
//  수집한 신호를 이 순수 구조체로 정규화해 엔진에 넘긴다.
//  엔진 자체는 어떤 플랫폼 프레임워크에도 의존하지 않는다.
//

import Foundation

/// 어젯밤 수면 요약 (HealthKit 어댑터가 채움, macOS 등에서는 nil 가능)
public struct SleepSummary: Sendable, Equatable {
    /// 실제 수면 시간 (초)
    public let asleepDuration: TimeInterval

    /// 기상 시각 (선택)
    public let wakeTime: Date?

    public init(asleepDuration: TimeInterval, wakeTime: Date? = nil) {
        self.asleepDuration = asleepDuration
        self.wakeTime = wakeTime
    }

    /// 수면 시간 (시간 단위)
    public var asleepHours: Double {
        asleepDuration / 3600
    }
}

/// 일정 간 이동 구간 (MapKit 어댑터가 채움, 없으면 빈 배열)
public struct TravelLeg: Sendable, Equatable {
    /// 출발 일정 id
    public let fromEventID: UUID

    /// 도착 일정 id
    public let toEventID: UUID

    /// 예상 이동 시간 (초)
    public let travelTime: TimeInterval

    public init(fromEventID: UUID, toEventID: UUID, travelTime: TimeInterval) {
        self.fromEventID = fromEventID
        self.toEventID = toEventID
        self.travelTime = travelTime
    }

    /// 이동 시간 (분 단위)
    public var travelMinutes: Double {
        travelTime / 60
    }
}

/// 하루 밀도 계산 입력.
///
/// `sleep`, `travel`이 비어 있으면 해당 신호는 점수에서 제외되고
/// 나머지 신호의 가중치가 재분배된다(graceful degrade).
public struct DensityInput: Sendable {
    /// 대상 날짜 (해당 일자의 일정만 평가)
    public let day: Date

    /// 그날의 일정 목록
    public let events: [Event]

    /// 어젯밤 수면 (없으면 nil → 수면 충돌 신호 제외)
    public let sleep: SleepSummary?

    /// 일정 간 이동 구간 (없으면 빈 배열 → 이동 부하 신호 제외)
    public let travel: [TravelLeg]

    /// 계산에 사용할 캘린더 (테스트 결정성 위해 주입)
    public let calendar: Calendar

    public init(
        day: Date,
        events: [Event],
        sleep: SleepSummary? = nil,
        travel: [TravelLeg] = [],
        calendar: Calendar = .current
    ) {
        self.day = day
        self.events = events
        self.sleep = sleep
        self.travel = travel
        self.calendar = calendar
    }
}
