//
//  TemplateAutocompleteView.swift
//  Nower
//
//  이벤트 템플릿 자동완성 드롭다운 뷰 (macOS)
//

import SwiftUI

#if canImport(NowerCore)
import NowerCore

/// 이벤트 템플릿 자동완성 드롭다운 — 최대 5개 행 표시
struct TemplateAutocompleteView: View {
    let suggestions: [EventTemplate]
    let onSelect: (EventTemplate) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.prefix(5).enumerated()), id: \.offset) { index, template in
                Button(action: { onSelect(template) }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AppColors.color(for: template.colorName))
                            .frame(width: 10, height: 10)

                        Text(template.name)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textPrimary)

                        if let rule = template.recurrenceRule {
                            Text(rule.displayString)
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textFieldPlaceholder)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)

                if index < min(suggestions.count, 5) - 1 {
                    Divider()
                        .padding(.horizontal, 10)
                }
            }
        }
        .background(AppColors.popupBackground)
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

#endif
