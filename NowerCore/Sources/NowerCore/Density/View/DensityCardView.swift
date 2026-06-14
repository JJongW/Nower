//
//  DensityCardView.swift
//  NowerCore
//
//  하루 밀도 카드 — iOS·macOS 공유 SwiftUI 뷰.
//  DensityViewState만 받아 렌더한다(순수 표현). 데이터 수집/채점은 외부.
//

import SwiftUI

/// 오늘의 밀도 카드. 점수 링 + 밴드 + narration + 제안 + 신호 분해.
public struct DensityCardView: View {
    private let state: DensityViewState
    /// 신호 분해 펼침 여부
    @State private var expanded: Bool = false

    public init(state: DensityViewState) {
        self.state = state
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Text(state.meaning)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(state.narration)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let suggestion = state.suggestion {
                suggestionRow(suggestion)
            }

            if !state.signalRows.isEmpty {
                disclosure
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.densityCardBackground)
        )
    }

    // MARK: - Header (점수 링 + 밴드)

    private var header: some View {
        HStack(spacing: 14) {
            scoreRing
            VStack(alignment: .leading, spacing: 2) {
                Text("오늘의 밀도")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(state.bandLabel)
                    .font(.headline)
                    .foregroundColor(bandColor)
            }
            Spacer()
        }
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(bandColor.opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0.001, state.progress))
                .stroke(bandColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(state.scoreText)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(bandColor)
        }
        .frame(width: 56, height: 56)
    }

    // MARK: - 제안

    private func suggestionRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            Text(text)
                .font(.footnote)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - 신호 분해

    private var disclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Text("신호 분해")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if expanded {
                ForEach(state.signalRows) { row in
                    signalRow(row)
                }
            }
        }
    }

    private func signalRow(_ row: DensityViewState.SignalRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(row.label)
                    .font(.caption.weight(.medium))
                Spacer()
                Text(row.detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(bandColor.opacity(0.7))
                        .frame(width: geo.size.width * CGFloat(max(0.02, min(1, row.intensity))))
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: - 색

    private var bandColor: Color {
        Color(densityHex: state.bandColorHex)
    }
}

// MARK: - Color helpers (패키지 자체 포함 — 앱 색 시스템과 독립)

extension Color {
    /// 카드 배경 (라이트/다크 자동)
    public static var densityCardBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }

    /// "#RRGGBB" hex → Color
    public init(densityHex hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
