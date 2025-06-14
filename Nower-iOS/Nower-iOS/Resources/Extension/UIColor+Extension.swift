//
//  UIColor+Extension.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit

enum AppColors {

    /// 기본 텍스트
    static let textPrimary: UIColor = #colorLiteral(red: 0.06274509804, green: 0.06274509804, blue: 0.06274509804, alpha: 1)
    static let textMain: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    static var textFieldPlacehorder: UIColor {
        let textFieldPlacehorder: UIColor = #colorLiteral(red: 0.831372549, green: 0.8235294118, blue: 0.8235294118, alpha: 1)
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? textFieldPlacehorder : textFieldPlacehorder
        }
    }

    /// 배경 색상
    static var background: UIColor {
        let background: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? background : background
        }
    }
    static var textFieldBackground: UIColor {
        let background: UIColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? background : background
        }
    }

    /// 팝업 배경
    static var popupBackground: UIColor {
        let popupBackground: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? popupBackground : popupBackground
        }
    }

    /// 강조 색
    static var textHighlighted: UIColor {
        let color: UIColor = #colorLiteral(red: 1, green: 0.4941176471, blue: 0.3843137255, alpha: 1) //#FF7E62
        return color
    }

    /// 버튼 색상
    static var buttonColor: UIColor {
        let buttonColor: UIColor = #colorLiteral(red: 0.06274509804, green: 0.06274509804, blue: 0.06274509804, alpha: 1)
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? buttonColor : buttonColor
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
    static let skyblue: UIColor = #colorLiteral(red: 0.6274509804, green: 0.8235294118, blue: 0.9215686275, alpha: 1)//UIColor(hex: "#A0D2EB")
    static let peach: UIColor = #colorLiteral(red: 1, green: 0.8392156863, blue: 0.6470588235, alpha: 1)//UIColor(hex: "#FFD6A5")
    static let lavender: UIColor = #colorLiteral(red: 0.7921568627, green: 0.7333333333, blue: 0.9137254902, alpha: 1)//UIColor(hex: "#CABBE9")
    static let mintgreen: UIColor = #colorLiteral(red: 0.4941176471, green: 0.8, blue: 0.6901960784, alpha: 1)//UIColor(hex: "#7ECCB0")
    static let coralred: UIColor = #colorLiteral(red: 1, green: 0.5882352941, blue: 0.5411764706, alpha: 1)//UIColor(hex: "#FF968A")

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
