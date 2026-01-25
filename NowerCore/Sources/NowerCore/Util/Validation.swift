//
//  Validation.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 유효성 검사 유틸리티
public enum Validation {
    /// 일정 유효성 검사 결과
    public struct EventValidationResult {
        public let isValid: Bool
        public let errors: [String]

        public init(isValid: Bool, errors: [String]) {
            self.isValid = isValid
            self.errors = errors
        }

        public static var valid: EventValidationResult {
            EventValidationResult(isValid: true, errors: [])
        }

        public static func invalid(_ errors: [String]) -> EventValidationResult {
            EventValidationResult(isValid: false, errors: errors)
        }
    }

    /// 일정 유효성 검사
    /// - Parameter event: 검사할 일정
    /// - Returns: 검사 결과
    public static func validate(_ event: Event) -> EventValidationResult {
        var errors: [String] = []

        // 제목 검사
        let trimmedTitle = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            errors.append("일정 제목을 입력해주세요")
        } else if trimmedTitle.count > 200 {
            errors.append("일정 제목은 200자 이하로 입력해주세요")
        }

        // 날짜 검사
        if event.endDateTime < event.startDateTime {
            errors.append("종료 시간이 시작 시간보다 빠릅니다")
        }

        // 기간 검사 (최대 365일)
        let maxDuration: TimeInterval = 365 * 24 * 60 * 60
        if event.duration > maxDuration {
            errors.append("일정 기간은 1년을 초과할 수 없습니다")
        }

        // 메모 길이 검사
        if let notes = event.notes, notes.count > 5000 {
            errors.append("메모는 5000자 이하로 입력해주세요")
        }

        // URL 검사
        if let url = event.url, url.absoluteString.count > 2000 {
            errors.append("URL이 너무 깁니다")
        }

        // 알림 개수 검사
        if event.reminders.count > 5 {
            errors.append("알림은 최대 5개까지 설정할 수 있습니다")
        }

        if errors.isEmpty {
            return .valid
        } else {
            return .invalid(errors)
        }
    }

    /// 제목 유효성 검사
    public static func validateTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 200
    }

    /// 날짜 범위 유효성 검사
    public static func validateDateRange(start: Date, end: Date) -> Bool {
        end >= start
    }

    /// 시간 입력 문자열 유효성 검사 (HH:mm 형식)
    public static func validateTimeString(_ timeString: String) -> Bool {
        let pattern = #"^([01]?[0-9]|2[0-3]):([0-5][0-9])$"#
        return timeString.range(of: pattern, options: .regularExpression) != nil
    }

    /// 날짜 입력 문자열 유효성 검사 (yyyy-MM-dd 형식)
    public static func validateDateString(_ dateString: String) -> Bool {
        DateFormatters.isoDate.date(from: dateString) != nil
    }
}

// MARK: - Event Validation Extension

public extension Event {
    /// 유효한 일정인지 검사
    var isValid: Bool {
        Validation.validate(self).isValid
    }

    /// 유효성 검사 에러 목록
    var validationErrors: [String] {
        Validation.validate(self).errors
    }
}
