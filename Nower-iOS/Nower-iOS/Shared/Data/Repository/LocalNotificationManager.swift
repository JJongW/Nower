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

    func cancelNotification(for todoId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [todoId.uuidString])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func rescheduleAll(todos: [TodoItem]) {
        cancelAllNotifications()
        for todo in todos where todo.hasReminder {
            scheduleNotification(for: todo)
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
