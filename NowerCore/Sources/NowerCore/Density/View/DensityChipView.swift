//
//  DensityChipView.swift
//  NowerCore
//
//  헤더용 컴팩트 밀도 칩 — iOS·macOS 공유.
//  색 도트 + 점수 + 밴드 라벨. 탭하면 상세 카드를 펼치도록 onTap 노출.
//

import SwiftUI

/// 한 줄짜리 밀도 칩. 공간 거의 안 씀.
public struct DensityChipView: View {
    private let state: DensityViewState
    private let onTap: (() -> Void)?

    public init(state: DensityViewState, onTap: (() -> Void)? = nil) {
        self.state = state
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(bandColor)
                    .frame(width: 7, height: 7)
                // 자기상대 표현 우선("평소보다 무거움"). 없으면 점수+밴드(콜드스타트/구버전).
                if let rel = state.relativeChipLabel {
                    Text(rel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                } else {
                    Text(state.scoreText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(state.bandLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(bandColor.opacity(0.12))
            )
            .overlay(
                Capsule().stroke(bandColor.opacity(0.35), lineWidth: 1)
            )
            .contentShape(Capsule())
            .fixedSize(horizontal: true, vertical: false) // 칩 내부 텍스트 잘림 방지
        }
        .buttonStyle(.plain)
        .accessibilityLabel("오늘의 여유, \(state.relativeChipLabel ?? state.bandLabel)")
    }

    private var bandColor: Color {
        Color(densityHex: state.bandColorHex)
    }
}
