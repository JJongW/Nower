//
//  ColorTheme.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 일정에 사용되는 색상 테마
/// macOS와 iOS에서 동일하게 사용됩니다.
public enum ColorTheme: String, Codable, CaseIterable, Hashable, Sendable {
    case skyblue
    case peach
    case lavender
    case mintgreen
    case coralred

    /// 기본 색상
    public static var `default`: ColorTheme { .skyblue }

    /// 한국어 표시명
    public var displayName: String {
        switch self {
        case .skyblue: return "하늘색"
        case .peach: return "복숭아"
        case .lavender: return "라벤더"
        case .mintgreen: return "민트"
        case .coralred: return "코랄"
        }
    }

    /// 영문 표시명
    public var displayNameEN: String {
        switch self {
        case .skyblue: return "Sky Blue"
        case .peach: return "Peach"
        case .lavender: return "Lavender"
        case .mintgreen: return "Mint Green"
        case .coralred: return "Coral Red"
        }
    }

    /// 레거시 colorName 문자열로부터 ColorTheme 생성
    /// - Parameter colorName: 기존 TodoItem의 colorName 값
    /// - Returns: 매칭되는 ColorTheme 또는 기본값
    public static func from(legacyColorName: String) -> ColorTheme {
        ColorTheme(rawValue: legacyColorName.lowercased()) ?? .default
    }
}
