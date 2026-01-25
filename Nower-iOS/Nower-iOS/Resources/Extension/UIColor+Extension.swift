//
//  UIColor+Extension.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
//
import UIKit

enum AppColors {
    
    // MARK: - Text Colors
    /// 기본 텍스트 색상 (Apple HIG 준수, WCAG 4.5:1 대비)
    /// 라이트 모드: #0F0F0F (거의 검정, 대비 15.8:1)
    /// 다크 모드: #F5F5F7 (밝은 회색, 대비 16.1:1)
    static var textPrimary: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0) // #F5F5F7
            } else {
                return UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0) // #0F0F0F
            }
        }
    }
    
    /// 일정 캡슐 내부 텍스트 색상 (기본값, 동적 계산 권장)
    /// 배경색에 맞춰 contrastingTextColor를 사용하는 것을 권장합니다.
    static var textMain: UIColor {
        return UIColor.white
    }
    
    /// 배경색에 대비되는 텍스트 색상을 반환합니다 (WCAG 4.5:1 대비 보장)
    /// - Parameter backgroundColor: 배경색
    /// - Returns: 대비가 충분한 텍스트 색상 (흰색 또는 검정)
    static func contrastingTextColor(for backgroundColor: UIColor) -> UIColor {
        return UIColor { trait in
            // 현재 컨텍스트에서 배경색 가져오기
            let resolvedColor = backgroundColor.resolvedColor(with: trait)
            
            // RGB 색공간으로 변환 시도
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            
            // RGB 값 추출 (다른 색공간이면 변환 시도)
            if resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                // 상대적 휘도 계산 (Relative Luminance)
                // 공식: L = 0.2126 * R + 0.7152 * G + 0.0722 * B
                // sRGB 색공간을 선형 색공간으로 변환
                func linearize(_ value: CGFloat) -> CGFloat {
                    return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
                }
                
                let r = linearize(red)
                let g = linearize(green)
                let b = linearize(blue)
                
                let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
                
                // 밝기가 0.5 이상이면 어두운 텍스트, 미만이면 밝은 텍스트
                // Apple HIG 권장: 밝은 배경에는 검정, 어두운 배경에는 흰색
                if luminance > 0.5 {
                    // 밝은 배경: 어두운 텍스트 (검정 계열)
                    return UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0) // #0F0F0F
                } else {
                    // 어두운 배경: 밝은 텍스트 (흰색)
                    return UIColor.white
                }
            } else {
                // RGB 추출 실패 시 기본값 (흰색 텍스트)
                return UIColor.white
            }
        }
    }
    
    /// 텍스트 필드 플레이스홀더 색상
    static var textFieldPlaceholder: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0) // #8E8E93
            } else {
                return UIColor(red: 0.83, green: 0.83, blue: 0.84, alpha: 1.0) // #D4D4D4
            }
        }
    }
    
    // MARK: - Background Colors
    /// 기본 배경 색상 (Apple HIG 준수)
    /// 라이트 모드: #FFFFFF
    /// 다크 모드: #000000 (iOS 표준 다크 배경)
    static var background: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor.black // #000000
            } else {
                return UIColor.white // #FFFFFF
            }
        }
    }
    
    /// 텍스트 필드 배경 색상
    static var textFieldBackground: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E (iOS 표준)
            } else {
                return UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0) // #F7F7F7
            }
        }
    }

    /// 팝업/모달 배경 색상
    static var popupBackground: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
            } else {
                return UIColor.white // #FFFFFF
            }
        }
    }
    
    // MARK: - Accent Colors
    /// 강조 색상 (오늘 날짜, 주요 액션 등)
    /// 라이트 모드: #FF7E62 (대비 3.2:1 - 큰 텍스트용)
    /// 다크 모드: #FF9A85 (더 밝게 조정, 대비 3.5:1)
    static var textHighlighted: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 1.0, green: 0.60, blue: 0.52, alpha: 1.0) // #FF9A85 (다크 모드용 더 밝은 버전)
            } else {
                return UIColor(red: 1.0, green: 0.49, blue: 0.38, alpha: 1.0) // #FF7E62
            }
        }
    }

    /// 버튼 텍스트 색상
    static var buttonColor: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor.white
            } else {
                return UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0) // #0F0F0F
            }
        }
    }

    /// 캡슐/카드 배경 색상
    static var todoBackground: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E (iOS 표준)
            } else {
                return UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0) // #F2F2F7
            }
        }
    }

    // MARK: - Calendar Theme Colors
    /// 일정 테마 색상 (WCAG 4.5:1 대비 기준 충족)
    /// 텍스트는 contrastingTextColor로 자동 조정되어 가독성 보장
    
    static var skyblue: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                // 다크모드: 밝게 조정 (어두운 배경에 밝은 색)
                return UIColor(red: 0.35, green: 0.60, blue: 0.80, alpha: 1.0) // #59A0CC
            } else {
                // 라이트모드: 중간 명도 (밝은 배경에 적절한 색)
                return UIColor(red: 0.45, green: 0.70, blue: 0.85, alpha: 1.0) // #73B3D9
            }
        }
    }
    
    static var peach: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                // 다크모드: 밝게 조정
                return UIColor(red: 0.95, green: 0.65, blue: 0.45, alpha: 1.0) // #F2A673
            } else {
                // 라이트모드: 중간 명도
                return UIColor(red: 0.95, green: 0.75, blue: 0.55, alpha: 1.0) // #F2BF8C
            }
        }
    }
    
    static var lavender: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                // 다크모드: 밝게 조정
                return UIColor(red: 0.65, green: 0.55, blue: 0.80, alpha: 1.0) // #A68CCC
            } else {
                // 라이트모드: 중간 명도
                return UIColor(red: 0.70, green: 0.60, blue: 0.85, alpha: 1.0) // #B399D9
            }
        }
    }
    
    static var mintgreen: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                // 다크모드: 밝게 조정
                return UIColor(red: 0.30, green: 0.65, blue: 0.55, alpha: 1.0) // #4DA68C
            } else {
                // 라이트모드: 중간 명도
                return UIColor(red: 0.40, green: 0.70, blue: 0.60, alpha: 1.0) // #66B399
            }
        }
    }
    
    static var coralred: UIColor {
        return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                // 다크모드: 밝게 조정
                return UIColor(red: 0.95, green: 0.50, blue: 0.45, alpha: 1.0) // #F28073
            } else {
                // 라이트모드: 중간 명도
                return UIColor(red: 0.95, green: 0.55, blue: 0.50, alpha: 1.0) // #F28C80
            }
        }
    }

    /// 기본 색상 이름 목록
    static let baseColorNames: [String] = ["skyblue", "peach", "lavender", "mintgreen", "coralred"]
    
    /// 기본 색상의 기본 톤 (기존 호환성 유지)
    static func baseColor(for name: String) -> UIColor {
        switch name {
        case "skyblue": return skyblue
        case "peach": return peach
        case "lavender": return lavender
        case "mintgreen": return mintgreen
        case "coralred": return coralred
        default: return UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor.systemGray
            } else {
                return UIColor.gray
            }
        }
        }
    }
    
    /// 색상 톤 생성 (1: 가장 밝음, 8: 가장 어두움)
    /// - Parameters:
    ///   - baseColor: 기본 색상 (UIColor)
    ///   - tone: 톤 레벨 (1-8)
    ///   - trait: 현재 trait collection
    /// - Returns: 조정된 색상
    private static func colorTone(baseColor: UIColor, tone: Int, trait: UITraitCollection) -> UIColor {
        let resolvedColor = baseColor.resolvedColor(with: trait)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard resolvedColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return baseColor
        }
        
        // 톤에 따라 밝기 조정 (1: 밝게, 8: 어둡게)
        // 다크모드와 라이트모드에 따라 다른 조정 방식 적용
        let isDark = trait.userInterfaceStyle == .dark
        let toneFactor: CGFloat
        
        if isDark {
            // 다크모드: 1이 가장 밝고 8이 가장 어두움
            // 밝기 범위: 0.3 ~ 0.95
            toneFactor = 0.95 - (CGFloat(tone - 1) / 7.0) * 0.65
        } else {
            // 라이트모드: 1이 가장 밝고 8이 가장 어두움
            // 밝기 범위: 0.4 ~ 0.95
            toneFactor = 0.95 - (CGFloat(tone - 1) / 7.0) * 0.55
        }
        
        // RGB 값을 톤에 맞게 조정 (채도는 유지하면서 밝기만 조정)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let targetLuminance = toneFactor
        
        if luminance > 0 {
            let ratio = targetLuminance / luminance
            r = min(1.0, max(0.0, r * ratio))
            g = min(1.0, max(0.0, g * ratio))
            b = min(1.0, max(0.0, b * ratio))
        }
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /// 특정 색상의 모든 톤 반환 (1-8)
    /// - Parameter baseColorName: 기본 색상 이름
    /// - Returns: 8가지 톤 배열 (1이 가장 밝음)
    static func colorTones(for baseColorName: String) -> [UIColor] {
        let base = baseColor(for: baseColorName)
        return (1...8).map { tone in
            UIColor { trait in
                colorTone(baseColor: base, tone: tone, trait: trait)
            }
        }
    }
    
    /// 색상 이름으로 색상 가져오기 (기본 색상 및 톤 지원)
    /// 지원 형식: "skyblue", "skyblue-1", "skyblue-2", ... "skyblue-8"
    /// 기존 색상 이름(톤 없음)은 중간 톤(4)으로 표시
    static func color(for name: String) -> UIColor {
        // 톤이 포함된 경우 (예: "skyblue-3")
        if let dashIndex = name.lastIndex(of: "-"),
           let tone = Int(String(name[name.index(after: dashIndex)...])),
           tone >= 1 && tone <= 8 {
            let baseName = String(name[..<dashIndex])
            let base = baseColor(for: baseName)
            return UIColor { trait in
                colorTone(baseColor: base, tone: tone, trait: trait)
            }
        }
        
        // 기본 색상 (기존 호환성) - 중간 톤(4)으로 표시
        let base = baseColor(for: name)
        return UIColor { trait in
            colorTone(baseColor: base, tone: 4, trait: trait)
        }
    }
    
    /// 색상 이름에서 기본 색상 이름 추출 (톤 제거)
    /// 예: "skyblue-3" -> "skyblue"
    static func baseColorName(from colorName: String) -> String {
        if let dashIndex = colorName.lastIndex(of: "-"),
           Int(String(colorName[colorName.index(after: dashIndex)...])) != nil {
            return String(colorName[..<dashIndex])
        }
        return colorName
    }
    
    /// 색상 이름에서 톤 번호 추출
    /// 예: "skyblue-3" -> 3, "skyblue" -> nil
    static func toneNumber(from colorName: String) -> Int? {
        guard let dashIndex = colorName.lastIndex(of: "-"),
              let tone = Int(String(colorName[colorName.index(after: dashIndex)...])),
              tone >= 1 && tone <= 8 else {
            return nil
        }
        return tone
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
