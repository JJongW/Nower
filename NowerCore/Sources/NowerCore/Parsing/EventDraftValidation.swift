//
//  EventDraftValidation.swift
//  NowerCore
//
//  파싱 초안의 일관성 검사 + 보정. 사용자에게 조용한 확인 문구를 띄울 때 사용.
//

import Foundation

public enum EventDraftValidation {

    public enum Issue: Sendable, Equatable {
        case missingTitle          // 제목이 비었다
        case noDateOrRecurrence    // 날짜도 반복도 없다 (호출부가 선택일로 보정 필요)
        case endBeforeStart        // 종료가 시작보다 빠르다
        case endWithoutStart       // 종료만 있고 시작이 없다
    }

    /// 초안에서 발견된 문제들
    public static func issues(_ draft: ParsedEventDraft) -> [Issue] {
        var result: [Issue] = []
        if draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
            result.append(.missingTitle)
        }
        if draft.date == nil && draft.recurrenceRule == nil {
            result.append(.noDateOrRecurrence)
        }
        if draft.endTime != nil && draft.startTime == nil {
            result.append(.endWithoutStart)
        }
        if let s = draft.startTime, let e = draft.endTime, e < s {
            result.append(.endBeforeStart)
        }
        return result
    }

    /// 자동 보정된 초안 (시작/종료 역전 시 교환, 시작 없는 종료 제거)
    public static func normalized(_ draft: ParsedEventDraft) -> ParsedEventDraft {
        var d = draft
        if d.endTime != nil && d.startTime == nil {
            d.endTime = nil
        }
        if let s = d.startTime, let e = d.endTime, e < s {
            d.startTime = e
            d.endTime = s
        }
        return d
    }

    /// 확신이 낮을 때 사용자에게 보여줄 조용한 확인 문구 (없으면 nil)
    public static func confirmationPrompt(_ draft: ParsedEventDraft) -> String? {
        guard draft.confidence != .high else { return nil }
        if let t = draft.startTime {
            return "\(t.hour)시\(draft.endTime != nil ? "부터" : "")로 볼까요?"
        }
        if draft.date != nil {
            return "이 날짜로 볼까요?"
        }
        return nil
    }
}
