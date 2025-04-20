//
//  UIColor+Extension.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit

enum AppColors {

    /// 기본 텍스트
    static let textPrimary = UIColor(hex: "#101010")
    static let textMain = UIColor(hex: "#FFFFFF")

    /// 배경 색상
    static var background: UIColor {
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#1C1C1E") : .white
        }
    }

    /// 팝업 배경
    static var popupBackground: UIColor {
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#2C2C2E") : UIColor(hex: "#FEFEFE")
        }
    }

    /// 강조 색
    static var textHighlighted: UIColor {
        return UIColor(hex: "#FF7E62")
    }

    /// 버튼 색상
    static var buttonColor: UIColor {
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: "#EEEEEE") : UIColor(hex: "#101010")
        }
    }

    /// 캡슐 뷰 배경
    static var todoBackground: UIColor {
        return UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.gray.withAlphaComponent(0.3)
                : UIColor.gray.withAlphaComponent(0.2)
        }
    }

    // 캘린더 테마 색 (고정)
    static let skyblue = UIColor(hex: "#A0D2EB")
    static let peach = UIColor(hex: "#FFD6A5")
    static let lavender = UIColor(hex: "#CABBE9")
    static let mintgreen = UIColor(hex: "#B5EAD7")
    static let coralred = UIColor(hex: "#FF968A")

    static func color(for name: String) -> UIColor {
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

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
