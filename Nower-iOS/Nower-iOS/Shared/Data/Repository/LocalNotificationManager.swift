//
//  LocalNotificationManager.swift
//  Nower-iOS
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation
import NowerCore
import UserNotifications
import UIKit

final class LocalNotificationManager: NSObject {
    static let shared = LocalNotificationManager()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
        registerDepartureCategory()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
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

        center.add(request)
    }

    // MARK: - Departure Nudge Notifications

    /// 출발 알림 ID 접두사. 일반 알림과 구분합니다.
    private static let departurePrefix = "departure-"

    /// 출발 알림 카테고리·액션 식별자.
    private enum DepartureAction {
        static let category = "DEPARTURE_NUDGE"
        static let openMap = "DEPARTURE_OPEN_MAP"
        static let snooze = "DEPARTURE_SNOOZE_10"
    }

    /// 출발 알림 userInfo 키.
    private enum DepartureKey {
        static let body = "body"
        static let originLat = "oLat"
        static let originLng = "oLng"
        static let destLat = "dLat"
        static let destLng = "dLng"
        static let destName = "destName"
    }

    /// "지도 열기"/"10분 미루기" 액션이 달린 출발 알림 카테고리를 등록합니다.
    private func registerDepartureCategory() {
        let openMap = UNNotificationAction(
            identifier: DepartureAction.openMap,
            title: "지도 열기",
            options: [.foreground]
        )
        let snooze = UNNotificationAction(
            identifier: DepartureAction.snooze,
            title: "10분 미루기",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: DepartureAction.category,
            actions: [openMap, snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    /// 출발 알림을 지정 시각에 예약합니다.
    /// - Parameters:
    ///   - todoId: 대상 일정 ID
    ///   - body: 알림 본문 (소요시간·기상 안내 문구)
    ///   - fireDate: 알림 발송 시각 (= 출발 준비 시작 시각)
    ///   - origin: 출발지 좌표 (지도 열기 길찾기 출발점)
    ///   - destination: 목적지 좌표 (지도 열기 길찾기 도착점)
    ///   - destinationName: 목적지 이름 (지도 마커 라벨)
    func scheduleDepartureNotification(
        todoId: UUID,
        body: String,
        fireDate: Date,
        origin: (lat: Double, lng: Double),
        destination: (lat: Double, lng: Double),
        destinationName: String
    ) {
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nower"
        content.body = body
        content.sound = .default
        content.categoryIdentifier = DepartureAction.category
        content.userInfo = [
            DepartureKey.body: body,
            DepartureKey.originLat: origin.lat,
            DepartureKey.originLng: origin.lng,
            DepartureKey.destLat: destination.lat,
            DepartureKey.destLng: destination.lng,
            DepartureKey.destName: destinationName
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.departurePrefix + todoId.uuidString,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// 특정 일정의 출발 알림을 취소합니다.
    func cancelDepartureNotification(for todoId: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.departurePrefix + todoId.uuidString]
        )
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

            center.add(request)
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        let info = response.notification.request.content.userInfo
        switch response.actionIdentifier {
        case DepartureAction.openMap, UNNotificationDefaultActionIdentifier:
            openDirections(from: info)
        case DepartureAction.snooze:
            snoozeDeparture(response.notification.request, by: 10 * 60)
        default:
            break
        }
    }

    // MARK: - Departure Actions

    /// 출발지·목적지가 채워진 길찾기를 외부 지도앱으로 엽니다.
    /// 카카오맵 → (실패 시) Apple 지도 순으로 폴백합니다.
    private func openDirections(from info: [AnyHashable: Any]) {
        guard let oLat = info[DepartureKey.originLat] as? Double,
              let oLng = info[DepartureKey.originLng] as? Double,
              let dLat = info[DepartureKey.destLat] as? Double,
              let dLng = info[DepartureKey.destLng] as? Double else { return }
        let destName = (info[DepartureKey.destName] as? String) ?? ""

        let kakao = URL(string: "kakaomap://route?sp=\(oLat),\(oLng)&ep=\(dLat),\(dLng)&by=CAR")
        let appleName = destName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let apple = URL(string: "http://maps.apple.com/?saddr=\(oLat),\(oLng)&daddr=\(dLat),\(dLng)&dirflg=d&q=\(appleName)")

        DispatchQueue.main.async {
            let app = UIApplication.shared
            if let kakao = kakao, app.canOpenURL(kakao) {
                app.open(kakao)
            } else if let apple = apple {
                app.open(apple)
            }
        }
    }

    /// 출발 알림을 지정 간격만큼 뒤로 다시 예약합니다("10분 미루기").
    private func snoozeDeparture(_ request: UNNotificationRequest, by seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = request.content.title
        content.body = request.content.body
        content.sound = request.content.sound
        content.categoryIdentifier = request.content.categoryIdentifier
        content.userInfo = request.content.userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let snoozed = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: trigger
        )
        center.add(snoozed)
    }
}
