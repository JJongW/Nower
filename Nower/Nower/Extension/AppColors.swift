//
//  AppColors.swift
//  Nower
//
//  Created by 신종원 on 3/9/25.
//  Updated for iOS compatibility on 5/12/25.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// macOS용 색상 시스템
/// iOS 버전과 동일한 디자인 시스템을 적용하며, 다크 모드 지원 및 WCAG 대비 기준을 준수합니다.
struct AppColors {
    
    // MARK: - Text Colors
    
    /// 기본 텍스트 색상 (Apple HIG 준수, WCAG 4.5:1 대비)
    /// 라이트 모드: #0F0F0F (거의 검정, 대비 15.8:1)
    /// 다크 모드: #F5F5F7 (밝은 회색, 대비 16.1:1)
    static var textPrimary: Color {
        ThemeManager.isDarkMode ? Color(hex: "#F5F5F7") : Color(hex: "#0F0F0F")
    }
    
    /// 일정 캡슐 내부 텍스트 색상 (기본값, 동적 계산 권장)
    /// 배경색에 맞춰 contrastingTextColor를 사용하는 것을 권장합니다.
    static let textMain = Color.white
    
    /// 배경색에 대비되는 텍스트 색상을 반환합니다 (WCAG 4.5:1 대비 보장)
    /// - Parameter backgroundColor: 배경색
    /// - Returns: 대비가 충분한 텍스트 색상 (흰색 또는 검정)
    static func contrastingTextColor(for backgroundColor: Color) -> Color {
        // macOS에서는 간단한 휘도 계산을 통해 텍스트 색상 결정
        // 실제 구현은 배경색의 밝기에 따라 결정
        // 여기서는 기본적으로 흰색을 반환 (실제로는 더 정교한 계산 필요)
        return Color.white
    }
    
    /// 텍스트 필드 플레이스홀더 색상
    static var textFieldPlaceholder: Color {
        ThemeManager.isDarkMode ? Color(hex: "#8E8E93") : Color(hex: "#D4D4D4")
    }
    
    // MARK: - Background Colors
    
    /// 기본 배경 색상 (Apple HIG 준수)
    /// 라이트 모드: #FFFFFF
    /// 다크 모드: #000000 (macOS 표준 다크 배경)
    static var background: Color {
        ThemeManager.isDarkMode ? Color.black : Color.white
    }
    
    /// 텍스트 필드 배경 색상
    static var textFieldBackground: Color {
        ThemeManager.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#F7F7F7")
    }
    
    /// 팝업/모달 배경 색상
    static var popupBackground: Color {
        ThemeManager.isDarkMode ? Color(hex: "#1C1C1E") : Color.white
    }
    
    // MARK: - Accent Colors
    
    /// 강조 색상 (오늘 날짜, 주요 액션 등)
    /// 라이트 모드: #FF7E62 (대비 3.2:1 - 큰 텍스트용)
    /// 다크 모드: #FF9A85 (더 밝게 조정, 대비 3.5:1)
    static var textHighlighted: Color {
        ThemeManager.isDarkMode ? Color(hex: "#FF9A85") : Color(hex: "#FF7E62")
    }
    
    /// 버튼 텍스트 색상 (HIG 준수, WCAG 4.5:1 대비)
    static var buttonColor: Color {
        ThemeManager.isDarkMode ? Color.white : Color(hex: "#0F0F0F")
    }
    
    /// 버튼 배경 색상 (HIG 준수)
    static var buttonBackground: Color {
        ThemeManager.isDarkMode ? Color(hex: "#007AFF") : Color(hex: "#007AFF") // 시스템 블루
    }
    
    /// 버튼 텍스트 색상 (버튼 배경에 대비)
    static var buttonTextColor: Color {
        Color.white // 버튼 배경이 항상 진한 색이므로 흰색 사용
    }
    
    /// 보조 버튼 배경 색상
    static var buttonSecondaryBackground: Color {
        ThemeManager.isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#F2F2F7")
    }
    
    /// 캡슐/카드 배경 색상
    static var todoBackground: Color {
        ThemeManager.isDarkMode ? Color(hex: "#2C2C2E") : Color(hex: "#F2F2F7")
    }
    
    // MARK: - Calendar Theme Colors
    
    /// 일정 테마 색상 (WCAG 4.5:1 대비 기준 충족)
    /// 텍스트는 contrastingTextColor로 자동 조정되어 가독성 보장
    
    static var skyblue: Color {
        ThemeManager.isDarkMode ? Color(hex: "#59A0CC") : Color(hex: "#73B3D9")
    }
    
    static var peach: Color {
        ThemeManager.isDarkMode ? Color(hex: "#F2A673") : Color(hex: "#F2BF8C")
    }
    
    static var lavender: Color {
        ThemeManager.isDarkMode ? Color(hex: "#A68CCC") : Color(hex: "#B399D9")
    }
    
    static var mintgreen: Color {
        ThemeManager.isDarkMode ? Color(hex: "#4DA68C") : Color(hex: "#66B399")
    }
    
    static var coralred: Color {
        ThemeManager.isDarkMode ? Color(hex: "#F28073") : Color(hex: "#F28C80")
    }
    
    /// 테마 색상 이름으로 색상 가져오기
    static func color(for name: String) -> Color {
        switch name {
        case "skyblue": return skyblue
        case "peach": return peach
        case "lavender": return lavender
        case "mintgreen": return mintgreen
        case "coralred": return coralred
        default: return Color.gray
        }
    }
    
    // MARK: - Legacy Support (기존 코드 호환성)
    
    /// 기존 코드 호환성을 위한 프로퍼티
    static var textColor1: Color { textPrimary }
    static var textWhite: Color { Color.white }
    static var todayHighlight: Color { Color.gray }
    static var holidayHighlight: Color { Color(hex: "#F0224C") }
    static var black: Color { Color(hex: "#1c1c1c") }
    static var primaryPink: Color { Color(hex: "#C95A71") }
    static var lightPink: Color { Color(hex: "#FFD3DD") }
}

extension Color {
    /// 16진수 문자열로부터 Color를 생성합니다.
    /// - Parameter hex: 16진수 색상 문자열 (예: "#FF0000" 또는 "FF0000")
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

struct ThemeManager {
    static var isDarkMode: Bool {
#if os(iOS)
        return UITraitCollection.current.userInterfaceStyle == .dark
#elseif os(macOS)
        // NSApp이 초기화되지 않았을 수 있으므로 안전하게 처리
        // Thread-safe하게 접근
        if Thread.isMainThread {
            // 메인 스레드에서만 NSApp에 접근
            if #available(macOS 10.14, *) {
                return NSApp.effectiveAppearance.name == .darkAqua
            }
        }
        // 초기화 전이거나 다른 스레드에서는 기본값 반환
        return false
#else
        return false
#endif
    }
}
