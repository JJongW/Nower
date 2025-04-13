//
//  AppDelegate.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        let VC = CalendarViewController()
        let navVC = UINavigationController(rootViewController: VC)
        window?.rootViewController = navVC
        window?.makeKeyAndVisible()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // ✅ 앱이 활성화될 때 무조건 iCloud 수동 동기화
        NSUbiquitousKeyValueStore.default.synchronize()
        print("✅ iCloud 수동 동기화 시도")
    }
}
