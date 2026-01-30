//
//  AppDelegate.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NSUbiquitousKeyValueStore.default.synchronize()

        // 알림 초기화: 모든 일정에 대해 알림 재예약
        let allTodos = CloudSyncManager.shared.getAllTodos()
        LocalNotificationManager.shared.rescheduleAll(todos: allTodos)

        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
