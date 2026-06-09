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
            LockScreenView(state: context.state, density: context.attributes.densityLabel)
                .activityBackgroundTint(Color(.systemBackground).opacity(0.88))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            let accent = densityColor(context.attributes.densityLabel)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    modeBadge(context.state.mode, accent: accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context.state.eventDate, size: 20)
                        .foregroundColor(accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(context.state.mode.label)
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
                Image(systemName: context.state.mode.symbol)
                    .foregroundColor(accent)
            } compactTrailing: {
                countdown(context.state.eventDate, size: 13)
                    .foregroundColor(accent)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: context.state.mode.symbol)
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

    private var accent: Color { densityColor(density) }

    var body: some View {
        HStack(spacing: 13) {
            // 모드 아이콘 — 부드러운 틴트 타일
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(accent.opacity(0.15))
                Image(systemName: state.mode.symbol)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundColor(accent)
            }
            .frame(width: 46, height: 46)

            // 제목 + 모드/보조
            VStack(alignment: .leading, spacing: 3) {
                Text(state.mode.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(accent)
                Text(state.eventTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(state.detail ?? "\(state.startTime) 시작")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // 카운트다운 + 밀도
            VStack(alignment: .trailing, spacing: 4) {
                countdown(state.eventDate, size: 24)
                    .foregroundColor(.primary)
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
        .font(.system(size: size, weight: .bold, design: .rounded).monospacedDigit())
        .multilineTextAlignment(.trailing)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
}

@available(iOS 16.1, *)
private func modeBadge(_ mode: NowerLiveActivityAttributes.Mode, accent: Color) -> some View {
    ZStack {
        Circle().fill(accent.opacity(0.15))
        Image(systemName: mode.symbol).font(.system(size: 15, weight: .medium)).foregroundColor(accent)
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
