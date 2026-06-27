//
//  NowerLiveActivity.swift
//  NowerTodayWidgetExtension
//
//  하루 밀도 Companion을 잠금화면 / Dynamic Island에 조용히 보여주는 Live Activity.
//  시간 알림 자체는 Local Notification이 담당하고, 여기서는 다음 일정·남은 시간·
//  집중 블록·이동 준비를 보조적으로 표시한다.
//
//  ⚠️ NowerCore(공유 attributes/색) 의존 — 위젯 익스텐션 타겟에 NowerCore 연결 필요.
//

#if os(iOS)
import ActivityKit
import WidgetKit
import SwiftUI
import NowerCore

@available(iOS 16.1, *)
struct NowerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowerLiveActivityAttributes.self) { context in
            // 배경 틴트를 시스템에 맡긴다. 커스텀 흰색 틴트는 라이트모드 잠금화면에서
            // 시스템이 흰 글자를 강제할 때 "흰 배경 + 흰 글자"로 글자가 사라지는 문제가 있었다.
            LockScreenView(state: context.state, density: context.attributes.densityLabel,
                           isStale: context.isStale)
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            // stale(종료/시작 시각 지남)이면 강조색을 죽이고 카운트다운을 멈춘다.
            let stale = context.isStale
            let accent = stale ? Color.secondary : densityColor(context.attributes.densityLabel)
            let symbol = displaySymbol(context.state.mode, isStale: stale)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    modeBadge(symbol, accent: accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdownOrEnded(context.state.eventDate, isStale: stale, size: 20)
                        .foregroundColor(accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayLabel(context.state.mode, isStale: stale))
                            .font(.caption2.weight(.semibold)).foregroundColor(accent)
                        Text(context.state.eventTitle)
                            .font(.system(size: 15, weight: .semibold)).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("\(context.state.startTime) 시작")
                            .font(.caption2).foregroundColor(.secondary)
                        Spacer()
                        densityPill(context.attributes.densityLabel, accent: accent)
                    }
                }
            } compactLeading: {
                Image(systemName: symbol)
                    .foregroundColor(accent)
            } compactTrailing: {
                countdownOrEnded(context.state.eventDate, isStale: stale, size: 13)
                    .foregroundColor(accent)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: symbol)
                    .foregroundColor(accent)
            }
            .keylineTint(accent)
        }
    }
}

// MARK: - 잠금화면

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let state: NowerLiveActivityAttributes.ContentState
    let density: String
    var isStale: Bool = false

    private var accent: Color { isStale ? .secondary : densityColor(density) }

    var body: some View {
        HStack(spacing: 13) {
            // 모드 아이콘 — 부드러운 틴트 타일
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(accent.opacity(0.15))
                Image(systemName: displaySymbol(state.mode, isStale: isStale))
                    .font(.system(size: 21, weight: .medium))
                    .foregroundColor(accent)
            }
            .frame(width: 46, height: 46)

            // 제목 + 모드/보조
            VStack(alignment: .leading, spacing: 3) {
                Text(displayLabel(state.mode, isStale: isStale))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(accent)
                Text(state.eventTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isStale ? .secondary : .primary)
                    .lineLimit(1)
                Text(isStale ? "방금 마무리됐어요" : (state.detail ?? "\(state.startTime) 시작"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // 카운트다운 + 밀도
            VStack(alignment: .trailing, spacing: 4) {
                countdownOrEnded(state.eventDate, isStale: isStale, size: 24)
                    .foregroundColor(isStale ? .secondary : .primary)
                densityPill(density, accent: accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - 공통 조각

@available(iOS 16.1, *)
private func countdown(_ date: Date, size: CGFloat) -> some View {
    Text(date, style: .timer)
        .font(.system(size: size, weight: .bold).monospacedDigit())
        .multilineTextAlignment(.trailing)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
}

/// stale이면 카운트다운 대신 "종료" 정적 텍스트(타이머가 음수로 흐르는 것 방지).
@available(iOS 16.1, *)
@ViewBuilder
private func countdownOrEnded(_ date: Date, isStale: Bool, size: CGFloat) -> some View {
    if isStale {
        Text("종료")
            .font(.system(size: size, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    } else {
        countdown(date, size: size)
    }
}

/// 모드 라벨 — stale이면 '종료됨'(예정 일정은 '시작 시각 지남')으로 정직하게.
@available(iOS 16.1, *)
private func displayLabel(_ mode: NowerLiveActivityAttributes.Mode, isStale: Bool) -> String {
    guard isStale else { return mode.label }
    switch mode {
    case .upcoming: return "시작 시각 지남"
    default: return "종료됨"
    }
}

/// 모드 심볼 — stale이면 완료 체크로.
@available(iOS 16.1, *)
private func displaySymbol(_ mode: NowerLiveActivityAttributes.Mode, isStale: Bool) -> String {
    isStale ? "checkmark.circle" : mode.symbol
}

@available(iOS 16.1, *)
private func modeBadge(_ symbol: String, accent: Color) -> some View {
    ZStack {
        Circle().fill(accent.opacity(0.15))
        Image(systemName: symbol).font(.system(size: 15, weight: .medium)).foregroundColor(accent)
    }
    .frame(width: 32, height: 32)
}

@available(iOS 16.1, *)
private func densityPill(_ label: String, accent: Color) -> some View {
    HStack(spacing: 4) {
        Circle().fill(accent).frame(width: 6, height: 6)
        Text("밀도 \(label)")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(Capsule().fill(accent.opacity(0.12)))
}

/// 밀도 라벨 → 밴드 색
@available(iOS 16.1, *)
private func densityColor(_ label: String) -> Color {
    switch label {
    case "과부하": return Color(densityHex: "#FF3B30")
    case "보통":   return Color(densityHex: "#FF9500")
    default:        return Color(densityHex: "#34C759") // 여유
    }
}
#endif
