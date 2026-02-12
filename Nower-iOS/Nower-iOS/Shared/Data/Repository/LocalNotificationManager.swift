//
//  LocalNotificationManager.swift
//  Nower-iOS
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation
import UserNotifications

final class LocalNotificationManager: NSObject {
    static let shared = LocalNotificationManager()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("❌ [LocalNotificationManager] 권한 요청 실패: \(error)")
            return false
        }
    }

    // MARK: - Schedule

    func scheduleNotification(for todo: TodoItem) {
        guard let reminderDate = todo.reminderDate else { return }

        // 과거 알림은 예약하지 않음
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nower"
        if let time = todo.scheduledTime {
            content.body = "\(time) \(todo.text)"
        } else {
            content.body = todo.text
        }
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: todo.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ [LocalNotificationManager] 알림 예약 실패: \(error)")
            }
        }
    }

    // MARK: - Recurring Event Notifications

    /// 반복 일정의 향후 10개 인스턴스에 대해 알림을 스케줄링합니다.
    func scheduleRecurringNotifications(for todo: TodoItem, maxInstances: Int = 10) {
        guard todo.isRecurringEvent,
              todo.hasReminder,
              let _ = todo.reminderMinutesBefore else { return }

        let today = Date()
        let futureLimit = Calendar.current.date(byAdding: .year, value: 1, to: today) ?? today
        let instances = RecurringEventExpander.occurrences(of: todo, from: today, to: futureLimit)

        for (index, instance) in instances.prefix(maxInstances).enumerated() {
            guard let reminderDate = instance.reminderDate, reminderDate > today else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Nower"
            if let time = instance.scheduledTime {
                content.body = "\(time) \(instance.text)"
            } else {
                content.body = instance.text
            }
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            // 시리즈용 고유 ID: "todoId-occurrence-index"
            let identifier = "\(todo.id.uuidString)-recurring-\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("❌ [LocalNotificationManager] 반복 알림 예약 실패: \(error)")
                }
            }
        }
    }

    /// 반복 일정 시리즈의 모든 알림을 취소합니다.
    func cancelSeriesNotifications(for todoId: UUID) {
        let prefix = todoId.uuidString
        center.getPendingNotificationRequests { [weak self] requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map { $0.identifier }
            self?.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func cancelNotification(for todoId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [todoId.uuidString])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func rescheduleAll(todos: [TodoItem]) {
        cancelAllNotifications()
        for todo in todos where todo.hasReminder {
            if todo.isRecurringEvent {
                scheduleRecurringNotifications(for: todo)
            } else {
                scheduleNotification(for: todo)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LocalNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 앱이 포그라운드일 때도 알림 표시
        completionHandler([.banner, .sound])
    }
}
