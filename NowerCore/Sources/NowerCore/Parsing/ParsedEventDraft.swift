//
//  ParsedEventDraft.swift
//  NowerCore
//
//  자연어 입력을 해석한 "초안". 바로 TodoItem/Event로 만들지 않고,
//  사용자가 확정(추가 버튼)하기 전 editable chip으로 보여줄 중간 모델이다.
//  AI Companion 원칙: 확인 없이 일정을 만들지 않는다.
//

import Foundation

/// 파싱 확신도 — 불확실하면 조용한 확인 문구를 띄우는 데 사용
public enum ParseConfidence: String, Sendable {
    case low      // 제목 정도만 추정
    case medium   // 날짜 또는 시간 중 하나
    case high     // 날짜 + 시간(또는 명확한 종일/반복)
}

/// 시·분 (24시간 기준)
public struct ParsedTime: Sendable, Equatable, Comparable {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    /// "HH:mm" 표기 (TodoItem.scheduledTime 형식과 호환)
    public var hhmm: String {
        String(format: "%02d:%02d", hour, minute)
    }

    public static func < (lhs: ParsedTime, rhs: ParsedTime) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}

/// 자연어에서 뽑아낸 일정 초안
public struct ParsedEventDraft: Sendable, Equatable {
    /// 인식된 토큰을 제거하고 남은 제목
    public var title: String
    /// 날짜 (없으면 nil → 호출부가 오늘/선택일로 보정)
    public var date: Date?
    /// 시작 시각 (nil이면 종일 후보)
    public var startTime: ParsedTime?
    /// 종료 시각 (선택)
    public var endTime: ParsedTime?
    /// 종일 일정 여부
    public var isAllDay: Bool
    /// 반복 규칙 (없으면 nil)
    public var recurrenceRule: RecurrenceRule?
    /// 확신도
    public var confidence: ParseConfidence

    public init(
        title: String = "",
        date: Date? = nil,
        startTime: ParsedTime? = nil,
        endTime: ParsedTime? = nil,
        isAllDay: Bool = true,
        recurrenceRule: RecurrenceRule? = nil,
        confidence: ParseConfidence = .low
    ) {
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
        self.recurrenceRule = recurrenceRule
        self.confidence = confidence
    }

    /// 비어 있는(아무 것도 인식 못한) 초안인지
    public var isEmpty: Bool {
        title.isEmpty && date == nil && startTime == nil && recurrenceRule == nil
    }
}
