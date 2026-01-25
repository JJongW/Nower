//
//  SettingsManager.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    /// 좌측 상단 고정 기능 활성화 여부
    @Published var isPinToTopLeft: Bool {
        didSet {
            UserDefaults.standard.set(isPinToTopLeft, forKey: "pinToTopLeft")
            NotificationCenter.default.post(name: .init("PinToTopLeftChanged"), object: nil)
        }
    }
    
    /// 항상 위에 표시 기능 활성화 여부
    @Published var isAlwaysOnTop: Bool {
        didSet {
            UserDefaults.standard.set(isAlwaysOnTop, forKey: "alwaysOnTop")
            NotificationCenter.default.post(name: .init("AlwaysOnTopChanged"), object: nil)
        }
    }

    init() {
        // 기본값 설정
        self.isPinToTopLeft = false
        self.isAlwaysOnTop = false

        DispatchQueue.main.async {
            // 저장된 설정 로드
            self.isPinToTopLeft = UserDefaults.standard.bool(forKey: "pinToTopLeft")
            self.isAlwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop")
        }
    }
}
