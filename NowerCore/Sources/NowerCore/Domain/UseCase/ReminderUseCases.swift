//
//  ReminderUseCases.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

// MARK: - Schedule Reminder

/// 알림 예약 UseCase
public protocol ScheduleReminderUseCase: Sendable {
    func execute(for event: Event, reminder: Reminder) async -> Result<Void, NowerError>
    func executeAll(for event: Event) async -> Result<Void, NowerError>
}

/// 알림 예약 UseCase 기본 구현
public final class DefaultScheduleReminderUseCase: ScheduleReminderUseCase, @unchecked Sendable {
    private let repository: ReminderRepository

    public init(repository: ReminderRepository) {
        self.repository = repository
    }

    public func execute(for event: Event, reminder: Reminder) async -> Result<Void, NowerError> {
        // 과거 일정에 대한 알림은 예약하지 않음
        let triggerDate = reminder.triggerDate(for: event.startDateTime)
        guard triggerDate > Date() else {
            return .success(()) // 과거 알림은 무시
        }

        // 권한 확인
        guard await repository.hasPermission() else {
            return .failure(.notificationPermissionDenied)
        }

        return await repository.schedule(for: event, reminder: reminder)
    }

    public func executeAll(for event: Event) async -> Result<Void, NowerError> {
        // 권한 확인
        guard await repository.hasPermission() else {
            return .failure(.notificationPermissionDenied)
        }

        for reminder in event.reminders {
            let result = await execute(for: event, reminder: reminder)
            if case .failure(let error) = result {
                return .failure(error)
            }
        }

        return .success(())
    }
}

// MARK: - Cancel Reminder

/// 알림 취소 UseCase
public protocol CancelReminderUseCase: Sendable {
    func execute(notificationId: String)
    func executeAll(for event: Event)
}

/// 알림 취소 UseCase 기본 구현
public final class DefaultCancelReminderUseCase: CancelReminderUseCase, @unchecked Sendable {
    private let repository: ReminderRepository

    public init(repository: ReminderRepository) {
        self.repository = repository
    }

    public func execute(notificationId: String) {
        repository.cancel(notificationId: notificationId)
    }

    public func executeAll(for event: Event) {
        repository.cancelAll(for: event)
    }
}

// MARK: - Reschedule All Reminders

/// 모든 알림 재예약 UseCase (앱 시작 시)
public protocol RescheduleAllRemindersUseCase: Sendable {
    func execute() async -> Result<Void, NowerError>
}

/// 모든 알림 재예약 UseCase 기본 구현
public final class DefaultRescheduleAllRemindersUseCase: RescheduleAllRemindersUseCase, @unchecked Sendable {
    private let eventRepository: EventRepository
    private let reminderRepository: ReminderRepository

    public init(eventRepository: EventRepository, reminderRepository: ReminderRepository) {
        self.eventRepository = eventRepository
        self.reminderRepository = reminderRepository
    }

    public func execute() async -> Result<Void, NowerError> {
        // 모든 일정 조회
        guard case .success(let events) = eventRepository.fetchAll() else {
            return .failure(.storageUnavailable)
        }

        // 미래 일정만 필터링 (알림이 있는 것만)
        let now = Date()
        let futureEvents = events.filter { event in
            event.startDateTime > now && !event.reminders.isEmpty
        }

        return await reminderRepository.rescheduleAll(for: futureEvents)
    }
}

// MARK: - Request Notification Permission

/// 알림 권한 요청 UseCase
public protocol RequestNotificationPermissionUseCase: Sendable {
    func execute() async -> Bool
}

/// 알림 권한 요청 UseCase 기본 구현
public final class DefaultRequestNotificationPermissionUseCase: RequestNotificationPermissionUseCase, @unchecked Sendable {
    private let repository: ReminderRepository

    public init(repository: ReminderRepository) {
        self.repository = repository
    }

    public func execute() async -> Bool {
        await repository.requestPermission()
    }
}
