//
//  main.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//  Enhanced for better error handling on 5/12/25.
//

import Foundation
import Cocoa

// SwiftUI 관련 경고 억제를 위한 환경 설정
if #available(macOS 11.0, *) {
    // macOS Big Sur 이상에서 SwiftUI 안정성 향상
    UserDefaults.standard.set(false, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

do {
    app.run()
} catch {
    print("❌ [main] 앱 실행 중 오류 발생: \(error)")
    NSLog("Nower 앱 실행 오류: \(error.localizedDescription)")
}
