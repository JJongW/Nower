//
//  TodoItem.swift
//  Nower-Shared
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

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
    let endScheduledTime: String?    // "HH:mm" 형식, 기간별 일정의 종료 시간 (nil = 하루 종일)
    let reminderMinutesBefore: Int?  // nil = 알림 없음, 0 = 정시, 5/10/30/60/1440
    
    /// 단일 날짜 TodoItem을 생성합니다. (기존 호환성 유지)
    /// - Parameters:
    ///   - text: Todo 내용
    ///   - isRepeating: 반복 여부
    ///   - date: 날짜 (yyyy-MM-dd 형식)
    ///   - colorName: 색상 이름
    init(text: String, isRepeating: Bool, date: String, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil) {
        self.text = text
        self.isRepeating = isRepeating
        self.date = date
        self.colorName = colorName
        self.startDate = nil
        self.endDate = nil
        self.scheduledTime = scheduledTime
        self.endScheduledTime = endScheduledTime
        self.reminderMinutesBefore = reminderMinutesBefore
    }
    
    /// Date 객체로부터 단일 날짜 TodoItem을 생성하는 편의 생성자 (기존 호환성 유지)
    /// - Parameters:
    ///   - text: Todo 내용
    ///   - isRepeating: 반복 여부
    ///   - date: Date 객체
    ///   - colorName: 색상 이름
    init(text: String, isRepeating: Bool, date: Date, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil) {
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
    }
    
    /// 기간별 TodoItem을 생성합니다.
    /// - Parameters:
    ///   - text: Todo 내용
    ///   - isRepeating: 반복 여부
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - colorName: 색상 이름
    init(text: String, isRepeating: Bool, startDate: Date, endDate: Date, colorName: String, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil) {
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
    }

    /// 모든 필드를 직접 지정하는 이니셜라이저 (NowerCore 변환용)
    /// - Parameters:
    ///   - id: 고유 식별자
    ///   - text: Todo 내용
    ///   - isRepeating: 반복 여부
    ///   - date: 날짜 문자열
    ///   - colorName: 색상 이름
    ///   - startDate: 시작 날짜 문자열 (기간별 일정용)
    ///   - endDate: 종료 날짜 문자열 (기간별 일정용)
    init(id: UUID, text: String, isRepeating: Bool, date: String, colorName: String, startDate: String? = nil, endDate: String? = nil, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil) {
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
    
    /// 날짜 문자열을 Date 객체로 변환합니다. (기존 date 필드)
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    /// 시작 날짜를 Date 객체로 변환합니다.
    var startDateObject: Date? {
        guard let startDate = startDate else { return dateObject } // 단일 날짜인 경우 date 반환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: startDate)
    }
    
    /// 종료 날짜를 Date 객체로 변환합니다.
    var endDateObject: Date? {
        guard let endDate = endDate else { return dateObject } // 단일 날짜인 경우 date 반환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: endDate)
    }
    
    /// 특정 날짜가 이 일정의 기간에 포함되는지 확인합니다.
    /// - Parameter date: 확인할 날짜
    /// - Returns: 기간에 포함되는지 여부
    func includesDate(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        if isPeriodEvent {
            // 기간별 일정인 경우
            guard let start = startDate, let end = endDate else { return false }
            return dateString >= start && dateString <= end
        } else {
            // 단일 날짜 일정인 경우
            return self.date == dateString
        }
    }
    
    /// 같은 날짜인지 확인합니다. (기존 호환성 유지)
    /// - Parameter date: 비교할 Date 객체
    /// - Returns: 같은 날짜인지 여부
    func isOnSameDate(as date: Date) -> Bool {
        return includesDate(date)
    }
    
    /// 일정의 전체 기간을 일 단위로 반환합니다.
    var durationInDays: Int {
        guard isPeriodEvent,
              let startDate = startDateObject,
              let endDate = endDateObject else { return 1 } // 단일 날짜는 1일

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1 // 시작일과 종료일을 모두 포함
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
}
