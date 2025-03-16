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
        }
    }
    
    @Published var backgroundColor: Color {
        didSet {
            let colorData = try? NSKeyedArchiver.archivedData(withRootObject: NSColor(backgroundColor), requiringSecureCoding: false)
            UserDefaults.standard.set(colorData, forKey: "calendarBackgroundColor")
        }
    }

    init() {
        self.opacity = 0.01 // 기본값 설정
        self.backgroundColor = .white // 기본값 설정

        DispatchQueue.main.async {
            let savedOpacity = UserDefaults.standard.double(forKey: "calendarOpacity")
            self.opacity = savedOpacity > 0 ? savedOpacity : 1.0

            if let savedColor = self.loadBackgroundColor() {
                self.backgroundColor = savedColor
            }
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
