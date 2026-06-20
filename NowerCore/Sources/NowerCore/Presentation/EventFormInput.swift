//
//  EventFormInput.swift
//  NowerCore
//
//  파싱 초안(ParsedEventDraft)을 "폼이 채워야 할 정규화된 값"으로 변환한다.
//  iOS·macOS가 각자 작성하던 적용 로직(applyNaturalLanguage / applyNLDraft)의 공통 핵심.
//  뷰 상태 타입(String "HH:mm" / Date)은 호출부가 매핑한다.
//

import Foundation

/// 폼에 주입할 정규화된 일정 입력값.
public struct EventFormInput: Sendable, Equatable {
    public var title: String
    public var date: Date?
    public var startHHmm: String?
    public var endHHmm: String?
    public var isAllDay: Bool
    public var recurrenceRule: RecurrenceRule?

    public init(
        title: String = "",
        date: Date? = nil,
        startHHmm: String? = nil,
        endHHmm: String? = nil,
        isAllDay: Bool = true,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        self.title = title
        self.date = date
        self.startHHmm = startHHmm
        self.endHHmm = endHHmm
        self.isAllDay = isAllDay
        self.recurrenceRule = recurrenceRule
    }
}

public extension EventFormInput {
    /// 파싱 초안을 폼 입력값으로 변환한다(역전/시작없는 종료 보정 포함).
    static func from(draft: ParsedEventDraft) -> EventFormInput {
        let n = EventDraftValidation.normalized(draft)
        return EventFormInput(
            title: n.title,
            date: n.date,
            startHHmm: n.startTime?.hhmm,
            endHHmm: n.endTime?.hhmm,
            isAllDay: n.startTime == nil,
            recurrenceRule: n.recurrenceRule
        )
    }
}
