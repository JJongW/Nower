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
    /// 신호 분해 펼침 여부 — 기본 펼침(숫자 근거를 숨기지 않는다)
    @State private var expanded: Bool = true

    public init(state: DensityViewState) {
        self.state = state
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let milestone = state.milestone {
                milestoneRow(milestone)
            }

            header

            Text(state.meaning)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(state.narration)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let callback = state.reflectionCallback {
                callbackRow(callback)
            }

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
                Text("오늘의 여유")
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

    // MARK: - 마일스톤 (벌어낸 학습 순간 — "너에 대해 하나 알아냈어")

    private func milestoneRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(bandColor)
                .font(.caption)
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(bandColor.opacity(0.14))
        )
    }

    // MARK: - 체감 콜백 (과거 기록 회상 — "나를 알아간다")

    private func callbackRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "quote.bubble.fill")
                .foregroundColor(bandColor)
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
                .fill(bandColor.opacity(0.10))
        )
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
                bandLegend
            }
        }
    }

    /// 밴드 경계 범례 — 점수가 어느 구간인지 한눈에(0–33 여유 / 34–66 보통 / 67–100 과부하)
    private var bandLegend: some View {
        HStack(spacing: 12) {
            legendItem("넉넉", "0–33", "#34C759")
            legendItem("보통", "34–66", "#FF9500")
            legendItem("빡빡", "67–100", "#FF3B30")
        }
        .padding(.top, 2)
    }

    private func legendItem(_ label: String, _ range: String, _ hex: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(Color(densityHex: hex)).frame(width: 6, height: 6)
            Text(label).font(.caption2.weight(.medium)).foregroundColor(.primary)
            Text(range).font(.caption2).foregroundColor(.secondary)
        }
    }

    private func signalRow(_ row: DensityViewState.SignalRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(row.label)
                    .font(.caption.weight(.medium))
                Text("+\(row.contributionPoints)점")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(bandColor)
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
