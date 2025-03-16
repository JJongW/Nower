//
//  AppColors.swift
//  Nower
//
//  Created by 신종원 on 3/9/25.
//

import Foundation
import SwiftUICore

struct AppColors {
    static let background = Color(hex: "#FFFFFF")
    static let textColor1 = Color(hex: "#101010")
    static let textHighlighted = Color(hex: "#FF7E62")
    static let todoBackground = Color.gray.opacity(0.2)
    static let popupBackground = Color(hex: "#101010")

    static let todayHighlight = Color.gray

    static let buttonColor = Color(hex: "#101010")
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
