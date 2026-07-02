//
//  TodoItem.swift
//  NowerCore
//
//  iOS·macOS·위젯이 공유하는 단일 일정 도메인/영속 모델.
//  (기존에 앱 타깃마다 이중 정의되던 것을 NowerCore 단일 정의로 승격.)
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

// MARK: - 반복 일정 규칙 정보

/// 반복 일정의 규칙을 정의하는 구조체
public struct RecurrenceInfo: Codable, Hashable {
    public let frequency: String      // "daily", "weekly", "monthly", "yearly"
    public let interval: Int          // 매 N 단위
    public let endDate: String?       // "yyyy-MM-dd" or nil = 무한
    public let endAfterCount: Int?    // N회 후 종료 (endDate 대안)
    public let daysOfWeek: [Int]?     // 주간: 1=일..7=토
    public let dayOfMonth: Int?       // 월간: 1-31

    public init(frequency: String, interval: Int = 1, endDate: String? = nil, endAfterCount: Int? = nil, daysOfWeek: [Int]? = nil, dayOfMonth: Int? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.endDate = endDate
        self.endAfterCount = endAfterCount
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
    }

    /// 사용자에게 표시할 요약 문자열
    public var displayString: String {
        let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

        if interval == 1 {
            switch frequency {
            case "daily": return "매일"
            case "weekly":
                if let days = daysOfWeek, !days.isEmpty {
                    let names = days.sorted().compactMap { d -> String? in
                        guard d >= 1 && d <= 7 else { return nil }
                        return weekdayNames[d - 1]
                    }
                    return "매주 " + names.joined(separator: ", ")
                }
                return "매주"
            case "monthly":
                if let day = dayOfMonth { return "매월 \(day)일" }
                return "매월"
            case "yearly": return "매년"
            default: return "반복"
            }
        } else {
            switch frequency {
            case "daily": return "\(interval)일마다"
            case "weekly":
                if let days = daysOfWeek, !days.isEmpty {
                    let names = days.sorted().compactMap { d -> String? in
                        guard d >= 1 && d <= 7 else { return nil }
                        return weekdayNames[d - 1]
                    }
                    return "\(interval)주마다 " + names.joined(separator: ", ")
                }
                return "\(interval)주마다"
            case "monthly": return "\(interval)개월마다"
            case "yearly": return "\(interval)년마다"
            default: return "반복"
            }
        }
    }
}

/// 반복 일정의 개별 인스턴스 예외를 정의하는 구조체
public struct RecurrenceException: Codable, Hashable {
    public let originalDate: String           // 해당 발생 날짜 "yyyy-MM-dd"
    public let isDeleted: Bool                // 이 인스턴스 삭제 여부
    public let overriddenTodo: TodoItem?      // 개별 수정된 데이터 (nil = 삭제만)

    public init(originalDate: String, isDeleted: Bool, overriddenTodo: TodoItem?) {
        self.originalDate = originalDate
        self.isDeleted = isDeleted
        self.overriddenTodo = overriddenTodo
    }
}

// MARK: - 반복 일정 수정/삭제 범위

/// 반복 일정 수정/삭제 시 적용 범위
public enum RecurrenceEditScope {
    case thisOnly       // 이 일정만
    case thisAndFuture  // 이 일정 및 향후 일정
    case all            // 모든 일정
}

/// 공통 Todo 아이템 데이터 모델
/// macOS·iOS·위젯에서 동일하게 사용되는 핵심 엔티티입니다.
/// 단일 날짜 및 기간별 일정을 모두 지원합니다.
public struct TodoItem: Identifiable, Codable {
    public var id = UUID()
    public let text: String
    public let isRepeating: Bool
    public let date: String // yyyy-MM-dd 형식 (기존 호환성을 위한 필드, 단일 날짜 또는 시작일)
    public let colorName: String

    // 기간별 일정을 위한 필드들
    public let startDate: String? // yyyy-MM-dd 형식, nil이면 단일 날짜 일정
    public let endDate: String?   // yyyy-MM-dd 형식, nil이면 단일 날짜 일정

    // 시간대별 일정 및 알림을 위한 필드들
    public let scheduledTime: String?       // "HH:mm" 형식, nil = 하루 종일
    public let endScheduledTime: String?    // "HH:mm" 형식, 종료 시각. nil = 종료 시간 없음 → 밀도/위젯은 시작 +1시간으로 처리
    public let reminderMinutesBefore: Int?  // nil = 알림 없음, 0 = 정시, 5/10/30/60/1440

    // 반복 일정을 위한 필드들
    public let recurrenceInfo: RecurrenceInfo?              // 반복 규칙 (nil = 비반복)
    public let recurrenceExceptions: [RecurrenceException]? // 예외 목록
    public let recurrenceSeriesId: UUID?                    // 분리된 시리즈 연결용

    // 외부 캘린더 연동 필드 (읽기 전용 미러). 자체 일정은 nil.
    public let externalSource: String?  // "apple" / "google" / "naver"
    public let externalID: String?      // 외부 원본 식별자 (dedup·재fetch 교체용)

    /// 단일 날짜 TodoItem을 생성합니다. (기존 호환성 유지)
    public init(text: String, isRepeating: Bool, date: String, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil, recurrenceInfo: RecurrenceInfo? = nil, recurrenceExceptions: [RecurrenceException]? = nil, recurrenceSeriesId: UUID? = nil, externalSource: String? = nil, externalID: String? = nil) {
        self.text = text
        self.isRepeating = isRepeating
        self.date = date
        self.colorName = colorName
        self.startDate = nil
        self.endDate = nil
        self.scheduledTime = scheduledTime
        self.endScheduledTime = endScheduledTime
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrenceInfo = recurrenceInfo
        self.recurrenceExceptions = recurrenceExceptions
        self.recurrenceSeriesId = recurrenceSeriesId
        self.externalSource = externalSource
        self.externalID = externalID
    }

    /// Date 객체로부터 단일 날짜 TodoItem을 생성하는 편의 생성자
    public init(text: String, isRepeating: Bool, date: Date, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil, recurrenceInfo: RecurrenceInfo? = nil, recurrenceExceptions: [RecurrenceException]? = nil, recurrenceSeriesId: UUID? = nil, externalSource: String? = nil, externalID: String? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        self.text = text
        self.isRepeating = isRepeating
        self.date = formatter.string(from: date)
        self.colorName = colorName
        self.startDate = nil
        self.endDate = nil
        self.scheduledTime = scheduledTime
        self.endScheduledTime = endScheduledTime
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrenceInfo = recurrenceInfo
        self.recurrenceExceptions = recurrenceExceptions
        self.recurrenceSeriesId = recurrenceSeriesId
        self.externalSource = externalSource
        self.externalID = externalID
    }

    /// 기간별 TodoItem을 생성합니다.
    public init(text: String, isRepeating: Bool, startDate: Date, endDate: Date, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil, recurrenceInfo: RecurrenceInfo? = nil, recurrenceExceptions: [RecurrenceException]? = nil, recurrenceSeriesId: UUID? = nil, externalSource: String? = nil, externalID: String? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        self.text = text
        self.isRepeating = isRepeating
        self.date = formatter.string(from: startDate) // 기존 호환성을 위해 시작일을 date에 저장
        self.colorName = colorName
        self.startDate = formatter.string(from: startDate)
        self.endDate = formatter.string(from: endDate)
        self.scheduledTime = scheduledTime
        self.endScheduledTime = endScheduledTime
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrenceInfo = recurrenceInfo
        self.recurrenceExceptions = recurrenceExceptions
        self.recurrenceSeriesId = recurrenceSeriesId
        self.externalSource = externalSource
        self.externalID = externalID
    }

    /// 모든 필드를 직접 지정하는 이니셜라이저 (변환·가상 인스턴스용)
    public init(id: UUID, text: String, isRepeating: Bool, date: String, colorName: String, startDate: String? = nil, endDate: String? = nil, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil, recurrenceInfo: RecurrenceInfo? = nil, recurrenceExceptions: [RecurrenceException]? = nil, recurrenceSeriesId: UUID? = nil, externalSource: String? = nil, externalID: String? = nil) {
        self.id = id
        self.text = text
        self.isRepeating = isRepeating
        self.date = date
        self.colorName = colorName
        self.startDate = startDate
        self.endDate = endDate
        self.scheduledTime = scheduledTime
        self.endScheduledTime = endScheduledTime
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrenceInfo = recurrenceInfo
        self.recurrenceExceptions = recurrenceExceptions
        self.recurrenceSeriesId = recurrenceSeriesId
        self.externalSource = externalSource
        self.externalID = externalID
    }
}

// MARK: - Hashable
extension TodoItem: Hashable {
    public static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 편의 메서드
extension TodoItem {
    /// 기간별 일정인지 확인합니다.
    public var isPeriodEvent: Bool {
        return startDate != nil && endDate != nil
    }

    /// 단일 날짜 일정인지 확인합니다.
    public var isSingleDayEvent: Bool {
        return !isPeriodEvent
    }

    /// 날짜 문자열을 Date 객체로 변환합니다. (기존 date 필드)
    public var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    /// 시작 날짜를 Date 객체로 변환합니다.
    public var startDateObject: Date? {
        guard let startDate = startDate else { return dateObject } // 단일 날짜인 경우 date 반환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: startDate)
    }

    /// 종료 날짜를 Date 객체로 변환합니다.
    public var endDateObject: Date? {
        guard let endDate = endDate else { return dateObject } // 단일 날짜인 경우 date 반환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: endDate)
    }

    /// 특정 날짜가 이 일정의 기간에 포함되는지 확인합니다.
    public func includesDate(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        if isPeriodEvent {
            guard let start = startDate, let end = endDate else { return false }
            return dateString >= start && dateString <= end
        } else {
            return self.date == dateString
        }
    }

    /// 같은 날짜인지 확인합니다. (기존 호환성 유지)
    public func isOnSameDate(as date: Date) -> Bool {
        return includesDate(date)
    }

    /// 일정의 전체 기간을 일 단위로 반환합니다.
    public var durationInDays: Int {
        guard isPeriodEvent,
              let startDate = startDateObject,
              let endDate = endDateObject else { return 1 } // 단일 날짜는 1일

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1 // 시작일과 종료일을 모두 포함
    }

    // MARK: - 시간/알림 관련 편의 프로퍼티

    /// 시간이 설정된 일정인지 확인합니다.
    public var hasScheduledTime: Bool {
        return scheduledTime != nil
    }

    /// 알림이 설정된 일정인지 확인합니다.
    public var hasReminder: Bool {
        return reminderMinutesBefore != nil
    }

    /// 날짜 + scheduledTime을 결합하여 Date 객체를 반환합니다.
    public var scheduledDateTime: Date? {
        guard let timeString = scheduledTime,
              let baseDate = dateObject else { return nil }
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }

    /// 알림 발송 시각을 반환합니다.
    public var reminderDate: Date? {
        guard let scheduled = scheduledDateTime,
              let minutes = reminderMinutesBefore else { return nil }
        return scheduled.addingTimeInterval(-Double(minutes) * 60)
    }

    // MARK: - 지난 일정 판정 — 시간 기반

    /// 일정이 끝나는 기준 시각.
    /// - 기간 일정: 종료일 끝(23:59:59)
    /// - 시간 일정: 종료 시각(있으면) / 없으면 시작 +1시간
    /// - 종일 단일 일정: 그날 끝
    public var endReference: Date? {
        let calendar = Calendar.current

        if isPeriodEvent, let end = endDateObject {
            return calendar.startOfDay(for: end).addingTimeInterval(86_399)
        }

        if let start = scheduledDateTime {
            if let endStr = endScheduledTime, let base = dateObject {
                let parts = endStr.split(separator: ":")
                if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]),
                   let end = calendar.date(bySettingHour: h, minute: m, second: 0, of: base),
                   end > start {
                    return end
                }
            }
            return start.addingTimeInterval(3600)
        }

        if let day = dateObject {
            return calendar.startOfDay(for: day).addingTimeInterval(86_399)
        }
        return nil
    }

    /// 종료 시각이 지나 '이미 지난 일정'인지 (시간 기반, 저장·동기화 없이 매번 계산).
    public var isPast: Bool {
        guard let end = endReference else { return false }
        return end < Date()
    }

    // MARK: - 외부 캘린더 연동 편의 프로퍼티

    /// 외부 캘린더에서 가져온 일정인지 여부.
    public var isExternal: Bool {
        return externalSource != nil
    }

    /// 읽기 전용(외부 미러) 일정인지 여부 — 편집/삭제 진입점 차단용.
    public var isReadOnly: Bool {
        return isExternal
    }

    // MARK: - 반복 일정 관련 편의 프로퍼티/메서드

    /// 반복 일정인지 확인합니다.
    public var isRecurringEvent: Bool {
        return recurrenceInfo != nil
    }

    /// 특정 날짜에 대한 가상 인스턴스를 생성합니다.
    public func virtualInstance(for date: Date) -> TodoItem {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return TodoItem(
            id: id,
            text: text,
            isRepeating: isRepeating,
            date: dateString,
            colorName: colorName,
            startDate: nil,
            endDate: nil,
            scheduledTime: scheduledTime,
            endScheduledTime: endScheduledTime,
            reminderMinutesBefore: reminderMinutesBefore,
            recurrenceInfo: recurrenceInfo,
            recurrenceExceptions: recurrenceExceptions,
            recurrenceSeriesId: recurrenceSeriesId,
            externalSource: externalSource,
            externalID: externalID
        )
    }

    /// 반복 규칙을 변경한 새 TodoItem을 반환합니다.
    public func withRecurrenceInfo(_ info: RecurrenceInfo?) -> TodoItem {
        return TodoItem(
            id: id,
            text: text,
            isRepeating: info != nil,
            date: date,
            colorName: colorName,
            startDate: startDate,
            endDate: endDate,
            scheduledTime: scheduledTime,
            endScheduledTime: endScheduledTime,
            reminderMinutesBefore: reminderMinutesBefore,
            recurrenceInfo: info,
            recurrenceExceptions: recurrenceExceptions,
            recurrenceSeriesId: recurrenceSeriesId,
            externalSource: externalSource,
            externalID: externalID
        )
    }

    /// 예외 목록을 변경한 새 TodoItem을 반환합니다.
    public func withExceptions(_ exceptions: [RecurrenceException]?) -> TodoItem {
        return TodoItem(
            id: id,
            text: text,
            isRepeating: isRepeating,
            date: date,
            colorName: colorName,
            startDate: startDate,
            endDate: endDate,
            scheduledTime: scheduledTime,
            endScheduledTime: endScheduledTime,
            reminderMinutesBefore: reminderMinutesBefore,
            recurrenceInfo: recurrenceInfo,
            recurrenceExceptions: exceptions,
            recurrenceSeriesId: recurrenceSeriesId,
            externalSource: externalSource,
            externalID: externalID
        )
    }
}
