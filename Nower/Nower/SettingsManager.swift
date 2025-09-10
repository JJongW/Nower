//
//  SettingsManager.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    @Published var opacity: Double {
        didSet {
            UserDefaults.standard.set(opacity, forKey: "calendarOpacity")
            NotificationCenter.default.post(name: .init("SettingsChanged"), object: nil)
        }
    }
    
    @Published var backgroundColor: Color {
        didSet {
            let colorData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(backgroundColor), requiringSecureCoding: false)
            UserDefaults.standard.set(colorData, forKey: "calendarBackgroundColor")
            NotificationCenter.default.post(name: .init("SettingsChanged"), object: nil)
        }
    }
    
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
        self.opacity = 0.01
        self.backgroundColor = .white
        self.isPinToTopLeft = false
        self.isAlwaysOnTop = false

        DispatchQueue.main.async {
            // 저장된 설정 로드
            let savedOpacity = UserDefaults.standard.double(forKey: "calendarOpacity")
            self.opacity = savedOpacity > 0 ? savedOpacity : 1.0

            if let savedColor = self.loadBackgroundColor() {
                self.backgroundColor = savedColor
            }
            
            // 새로운 설정들 로드
            self.isPinToTopLeft = UserDefaults.standard.bool(forKey: "pinToTopLeft")
            self.isAlwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop")
        }
    }

    private func saveBackgroundColor() {
        if let nsColor = NSColor(backgroundColor).usingColorSpace(.sRGB) {
            let colorData = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false)
            UserDefaults.standard.set(colorData, forKey: "calendarBackgroundColor")
        }
    }

    private func loadBackgroundColor() -> Color? {
        if let colorData = UserDefaults.standard.data(forKey: "calendarBackgroundColor") {
            do {
                let nsColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData)
                if let nsColor = nsColor {
                    return Color(nsColor)
                }
            } catch {
                print("Failed to unarchive color: \(error)")
            }
        }
        return nil
    }
}
