//
//  NowerCore.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// NowerCore 모듈의 버전 정보
public enum NowerCoreInfo {
    /// 현재 모듈 버전
    public static let version = "1.0.0"

    /// 데이터 스키마 버전
    public static let schemaVersion = 2

    /// 빌드 정보
    public static var buildInfo: String {
        "NowerCore v\(version) (Schema v\(schemaVersion))"
    }
}

// MARK: - Re-exports

// Domain Entities
// Event, CalendarDay, WeekDayInfo, ColorTheme, Location, Reminder, RecurrenceRule, SyncStatus
// LegacyTodoItem (for migration)

// Domain Errors
// NowerError

// Domain Repositories
// EventRepository, ReminderRepository, ScheduledReminder

// Domain Use Cases
// AddEventUseCase, DeleteEventUseCase, UpdateEventUseCase, FetchEventsUseCase, MoveEventUseCase
// DeleteRecurringEventsUseCase
// ScheduleReminderUseCase, CancelReminderUseCase, RescheduleAllRemindersUseCase
// RequestNotificationPermissionUseCase

// Data Storage
// StorageProvider, StorageKeys
// iCloudStorageProvider, LocalStorageProvider, InMemoryStorageProvider
// EventRepositoryImpl

// Data Sync
// SyncManager, iCloudSyncManager, LocalSyncManager
// EventMigrator, MigrationManager

// Utilities
// DateFormatters, Validation, CalendarDayGenerator

// Notifications
// Notification.Name.eventsDidUpdate, syncDidStart, syncDidComplete, syncDidFail
