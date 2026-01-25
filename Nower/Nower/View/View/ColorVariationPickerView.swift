//
//  ColorVariationPickerView.swift
//  Nower
//
//  Created by AI Assistant on 2026/01/25.
//

import SwiftUI

/// 색상 variation 선택을 위한 팝오버 뷰 (macOS SwiftUI 버전)
struct ColorVariationPickerView: View {
    let baseColorName: String
    let selectedTone: Int?
    let onColorSelected: (String) -> Void
    
    private let buttonSize: CGFloat = 32
    private let buttonSpacing: CGFloat = 6
    
    var body: some View {
        VStack(spacing: 16) {
            Text("색상 톤 선택")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: buttonSpacing) {
                ForEach(1...8, id: \.self) { tone in
                    Button(action: {
                        let colorName = "\(baseColorName)-\(tone)"
                        onColorSelected(colorName)
                    }) {
                        Circle()
                            .fill(AppColors.color(for: "\(baseColorName)-\(tone)"))
                            .frame(width: buttonSize, height: buttonSize)
                            .overlay(
                                Circle().stroke(
                                    selectedTone == tone ? borderColor : Color.clear,
                                    lineWidth: selectedTone == tone ? 2.5 : 0
                                )
                            )
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(16)
        .background(AppColors.popupBackground)
        .cornerRadius(16)
    }
    
    /// 선택된 색상에 맞는 테두리 색상 (다크모드/라이트모드에 따라)
    private var borderColor: Color {
        ThemeManager.isDarkMode ? Color.white : Color(hex: "#0F0F0F")
    }
}
