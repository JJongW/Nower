//
//  Reminder.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 일정 알림 설정
public struct Reminder: Codable, Hashable, Sendable, Identifiable {
    /// 알림 유형
    public enum ReminderType: String, Codable, CaseIterable, Sendable {
        /// 일정 시작 시간에 알림
        case atTime
        /// N분 전 알림
        case minutesBefore
        /// N시간 전 알림
        case hoursBefore
        /// N일 전 알림
        case daysBefore
    }

    /// 고유 식별자 (알림 취소용)
    public let id: UUID

    /// 알림 유형
    public let type: ReminderType

    /// 알림 값 (분/시간/일 수)
    public let value: Int

    /// 시스템 알림 식별자 (예약된 알림 관리용)
    public var notificationId: String {
        id.uuidString
    }

    public init(
        id: UUID = UUID(),
        type: ReminderType,
        value: Int = 0
    ) {
        self.id = id
        self.type = type
        self.value = value
    }

    /// 일정 시작 시간 기준으로 알림 시간 계산
    /// - Parameter eventStart: 일정 시작 시간
    /// - Returns: 알림이 발생해야 하는 시간
    public func triggerDate(for eventStart: Date) -> Date {
        switch type {
        case .atTime:
            return eventStart
        case .minutesBefore:
            return eventStart.addingTimeInterval(-Double(value) * 60)
        case .hoursBefore:
            return eventStart.addingTimeInterval(-Double(value) * 3600)
        case .daysBefore:
            return Calendar.current.date(byAdding: .day, value: -value, to: eventStart) ?? eventStart
        }
    }

    /// 표시용 문자열
    public var displayString: String {
        switch type {
        case .atTime:
            return "정시 알림"
        case .minutesBefore:
            return "\(value)분 전"
        case .hoursBefore:
            return "\(value)시간 전"
        case .daysBefore:
            return "\(value)일 전"
        }
    }
}

// MARK: - Preset Reminders

public extension Reminder {
    /// 정시 알림
    static var atTime: Reminder {
        Reminder(type: .atTime)
    }

    /// 5분 전 알림
    static var fiveMinutesBefore: Reminder {
        Reminder(type: .minutesBefore, value: 5)
    }

    /// 10분 전 알림
    static var tenMinutesBefore: Reminder {
        Reminder(type: .minutesBefore, value: 10)
    }

    /// 15분 전 알림
    static var fifteenMinutesBefore: Reminder {
        Reminder(type: .minutesBefore, value: 15)
    }

    /// 30분 전 알림
    static var thirtyMinutesBefore: Reminder {
        Reminder(type: .minutesBefore, value: 30)
    }

    /// 1시간 전 알림
    static var oneHourBefore: Reminder {
        Reminder(type: .hoursBefore, value: 1)
    }

    /// 1일 전 알림
    static var oneDayBefore: Reminder {
        Reminder(type: .daysBefore, value: 1)
    }

    /// 기본 알림 프리셋 목록
    static var presets: [Reminder] {
        [
            .atTime,
            .fiveMinutesBefore,
            .tenMinutesBefore,
            .fifteenMinutesBefore,
            .thirtyMinutesBefore,
            .oneHourBefore,
            .oneDayBefore
        ]
    }
}
