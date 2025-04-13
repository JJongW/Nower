//
//  UIColor+Extension.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//

import UIKit
import Foundation
import SwiftUICore

struct AppColors {
    static let background = Color(hex: "#FFFFFF")
    static let textColor1 = Color(hex: "#101010")
    static let textWhite = Color(hex: "#FFFFFF")
    static let textHighlighted = Color(hex: "#FF7E62")
    static let todoBackground = Color.gray.opacity(0.2)
    static let popupBackground = Color(hex: "#101010")

    static let todayHighlight = Color.gray

    static let buttonColor = Color(hex: "#101010")
    static let primaryPink = Color(hex: "#C95A71")
    static let lightPink = Color(hex: "#FFD3DD")

    static let black = Color(hex: "#1c1c1c")


    // 달력 선택 컬러
    static let skyblue = Color(hex: "#A0D2EB")
    static let peach = Color(hex: "#FFD6A5")
    static let lavender = Color(hex: "#CABBE9")
    static let mintgreen = Color(hex: "#B5EAD7")
    static let coralred = Color(hex: "#FF968A")

    static func color(for name: String) -> Color {
        switch name {
        case "skyblue": return skyblue
        case "peach": return peach
        case "lavender": return lavender
        case "mintgreen": return mintgreen
        case "coralred": return coralred
        default: return .gray
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
