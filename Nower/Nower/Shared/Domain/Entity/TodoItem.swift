//
//  TodoItem.swift
//  Nower-Shared
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

// MARK: - 반복 일정 규칙 정보

/// 반복 일정의 규칙을 정의하는 구조체
struct RecurrenceInfo: Codable, Hashable {
    let frequency: String      // "daily", "weekly", "monthly", "yearly"
    let interval: Int          // 매 N 단위
    let endDate: String?       // "yyyy-MM-dd" or nil = 무한
    let endAfterCount: Int?    // N회 후 종료 (endDate 대안)
    let daysOfWeek: [Int]?     // 주간: 1=일..7=토
    let dayOfMonth: Int?       // 월간: 1-31

    init(frequency: String, interval: Int = 1, endDate: String? = nil, endAfterCount: Int? = nil, daysOfWeek: [Int]? = nil, dayOfMonth: Int? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.endDate = endDate
        self.endAfterCount = endAfterCount
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
    }

    /// 사용자에게 표시할 요약 문자열
    var displayString: String {
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
struct RecurrenceException: Codable, Hashable {
    let originalDate: String           // 해당 발생 날짜 "yyyy-MM-dd"
    let isDeleted: Bool                // 이 인스턴스 삭제 여부
    let overriddenTodo: TodoItem?      // 개별 수정된 데이터 (nil = 삭제만)
}

// MARK: - 반복 일정 수정/삭제 범위

/// 반복 일정 수정/삭제 시 적용 범위
enum RecurrenceEditScope {
    case thisOnly       // 이 일정만
    case thisAndFuture  // 이 일정 및 향후 일정
    case all            // 모든 일정
}

/// 공통 Todo 아이템 데이터 모델
/// MacOS와 iOS에서 동일하게 사용되는 핵심 엔티티입니다.
/// 단일 날짜 및 기간별 일정을 모두 지원합니다.
struct TodoItem: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isRepeating: Bool
    let date: String // yyyy-MM-dd 형식 (기존 호환성을 위한 필드, 단일 날짜 또는 시작일)
    let colorName: String

    // 기간별 일정을 위한 새로운 필드들
    let startDate: String? // yyyy-MM-dd 형식, nil이면 단일 날짜 일정
    let endDate: String?   // yyyy-MM-dd 형식, nil이면 단일 날짜 일정

    // 시간대별 일정 및 알림을 위한 필드들
    let scheduledTime: String?       // "HH:mm" 형식, nil = 하루 종일
    let endScheduledTime: String?    // "HH:mm" 형식, 기간별 일정의 종료 시간
    let reminderMinutesBefore: Int?  // nil = 알림 없음

    // 반복 일정을 위한 필드들
    let recurrenceInfo: RecurrenceInfo?              // 반복 규칙 (nil = 비반복)
    let recurrenceExceptions: [RecurrenceException]? // 예외 목록
    let recurrenceSeriesId: UUID?                    // 분리된 시리즈 연결용

    /// 단일 날짜 TodoItem을 생성합니다. (기존 호환성 유지)
    init(text: String, isRepeating: Bool, date: String, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil, recurrenceInfo: RecurrenceInfo? = nil, recurrenceExceptions: [RecurrenceException]? = nil, recurrenceSeriesId: UUID? = nil) {
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
    }

    /// Date 객체로부터 단일 날짜 TodoItem을 생성하는 편의 생성자
    init(text: String, isRepeating: Bool, date: Date, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil, recurrenceInfo: RecurrenceInfo? = nil, recurrenceExceptions: [RecurrenceException]? = nil, recurrenceSeriesId: UUID? = nil) {
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
    }

    /// 기간별 TodoItem을 생성합니다.
    init(text: String, isRepeating: Bool, startDate: Date, endDate: Date, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil, recurrenceInfo: RecurrenceInfo? = nil, recurrenceExceptions: [RecurrenceException]? = nil, recurrenceSeriesId: UUID? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        self.text = text
        self.isRepeating = isRepeating
        self.date = formatter.string(from: startDate)
        self.colorName = colorName
        self.startDate = formatter.string(from: startDate)
        self.endDate = formatter.string(from: endDate)
        self.scheduledTime = scheduledTime
        self.endScheduledTime = endScheduledTime
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrenceInfo = recurrenceInfo
        self.recurrenceExceptions = recurrenceExceptions
        self.recurrenceSeriesId = recurrenceSeriesId
    }

    /// 모든 필드를 직접 지정하는 이니셜라이저
    init(id: UUID, text: String, isRepeating: Bool, date: String, colorName: String, startDate: String? = nil, endDate: String? = nil, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil, recurrenceInfo: RecurrenceInfo? = nil, recurrenceExceptions: [RecurrenceException]? = nil, recurrenceSeriesId: UUID? = nil) {
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
    }
}

// MARK: - Hashable
extension TodoItem: Hashable {
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 편의 메서드
extension TodoItem {
    /// 기간별 일정인지 확인합니다.
    var isPeriodEvent: Bool {
        return startDate != nil && endDate != nil
    }

    /// 단일 날짜 일정인지 확인합니다.
    var isSingleDayEvent: Bool {
        return !isPeriodEvent
    }

    /// 날짜 문자열을 Date 객체로 변환합니다.
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    /// 시작 날짜를 Date 객체로 변환합니다.
    var startDateObject: Date? {
        guard let startDate = startDate else { return dateObject }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: startDate)
    }

    /// 종료 날짜를 Date 객체로 변환합니다.
    var endDateObject: Date? {
        guard let endDate = endDate else { return dateObject }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: endDate)
    }

    /// 특정 날짜가 이 일정의 기간에 포함되는지 확인합니다.
    func includesDate(_ date: Date) -> Bool {
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

    /// 같은 날짜인지 확인합니다.
    func isOnSameDate(as date: Date) -> Bool {
        return includesDate(date)
    }

    /// 일정의 전체 기간을 일 단위로 반환합니다.
    var durationInDays: Int {
        guard isPeriodEvent,
              let startDate = startDateObject,
              let endDate = endDateObject else { return 1 }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }

    // MARK: - 시간/알림 관련 편의 프로퍼티

    /// 시간이 설정된 일정인지 확인합니다.
    var hasScheduledTime: Bool {
        return scheduledTime != nil
    }

    /// 알림이 설정된 일정인지 확인합니다.
    var hasReminder: Bool {
        return reminderMinutesBefore != nil
    }

    /// 날짜 + scheduledTime을 결합하여 Date 객체를 반환합니다.
    var scheduledDateTime: Date? {
        guard let timeString = scheduledTime,
              let baseDate = dateObject else { return nil }
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }

    /// 알림 발송 시각을 반환합니다.
    var reminderDate: Date? {
        guard let scheduled = scheduledDateTime,
              let minutes = reminderMinutesBefore else { return nil }
        return scheduled.addingTimeInterval(-Double(minutes) * 60)
    }

    // MARK: - 반복 일정 관련 편의 프로퍼티/메서드

    /// 반복 일정인지 확인합니다.
    var isRecurringEvent: Bool {
        return recurrenceInfo != nil
    }

    /// 특정 날짜에 대한 가상 인스턴스를 생성합니다.
    func virtualInstance(for date: Date) -> TodoItem {
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
            recurrenceSeriesId: recurrenceSeriesId
        )
    }

    /// 반복 규칙을 변경한 새 TodoItem을 반환합니다.
    func withRecurrenceInfo(_ info: RecurrenceInfo?) -> TodoItem {
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
            recurrenceSeriesId: recurrenceSeriesId
        )
    }

    /// 예외 목록을 변경한 새 TodoItem을 반환합니다.
    func withExceptions(_ exceptions: [RecurrenceException]?) -> TodoItem {
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
            recurrenceSeriesId: recurrenceSeriesId
        )
    }
}
