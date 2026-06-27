//
//  NowerLiveActivityManager.swift
//  Nower-iOS
//
//  Live Activity(Companion UI) 시작/갱신/종료 관리. 동시에 하나만 유지한다.
//
//  원칙:
//  - 정확한 시간 알림은 LocalNotificationManager(UNUserNotificationCenter)가 담당한다.
//  - 이 매니저는 다음 일정/남은 시간/집중 블록/이동 준비를 보여주는 보조 Companion이다.
//  - 일정 시작·준비 시각엔 local notification을 보내고, 동시에 여기 상태를 갱신한다.
//  - 중요한 갱신엔 ActivityKit alertConfiguration을 보조 알림으로만 쓴다.
//

#if os(iOS)
import ActivityKit
import Foundation
#if canImport(NowerCore)
import NowerCore
#endif

@available(iOS 16.2, *)
final class NowerLiveActivityManager {

    static let shared = NowerLiveActivityManager()
    private init() {}

    #if canImport(NowerCore)
    private var current: Activity<NowerLiveActivityAttributes>?

    /// 사용자가 Live Activity를 켤 수 있는 상태인지
    var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Companion 시작. 기존 활동이 있으면 먼저 종료한다(동시에 하나만).
    func start(densityLabel: String, state: NowerLiveActivityAttributes.ContentState) {
        guard isEnabled else {
            #if DEBUG
            print("[LiveActivity] 비활성 — 설정에서 라이브 액티비티 허용 필요")
            #endif
            return
        }
        Task {
            await endCurrent()
            let attributes = NowerLiveActivityAttributes(densityLabel: densityLabel)
            let content = ActivityContent(
                state: state,
                staleDate: state.eventDate // 기준 시각(진행 중=종료, 예정=시작)에 stale
            )
            do {
                current = try Activity.request(attributes: attributes, content: content, pushType: nil)
                #if DEBUG
                print("[LiveActivity] 시작됨: \(state.eventTitle) @ \(state.startTime)")
                #endif
            } catch {
                #if DEBUG
                print("[LiveActivity] 시작 실패: \(error)")
                #endif
            }
        }
    }

    /// 상태 갱신. 중요한 변화는 alert로 보조 알림(선택).
    /// staleDate를 일정 종료 시각(진행 중) / 시작 시각(예정)에 정확히 박아, push 없이도
    /// 종료 직후 시스템이 stale 처리 → 위젯이 '종료됨'으로 전환하도록 한다.
    /// (백그라운드에선 update가 못 도므로, '진행 중'이 끝나도 stale로 정직하게 표시.)
    func update(_ state: NowerLiveActivityAttributes.ContentState, alert: AlertConfiguration? = nil) {
        Task {
            let content = ActivityContent(
                state: state,
                staleDate: state.eventDate
            )
            await current?.update(content, alertConfiguration: alert)
        }
    }

    /// Companion 종료
    func end() {
        Task { await endCurrent() }
    }

    private func endCurrent() async {
        await current?.end(nil, dismissalPolicy: .immediate)
        current = nil
    }

    // MARK: - 편의

    /// 다음 일정까지의 카운트다운 Companion 시작
    func startUpcoming(title: String, eventDate: Date, startTime: String, densityLabel: String) {
        let state = NowerLiveActivityAttributes.ContentState(
            eventTitle: title,
            eventDate: eventDate,
            startTime: startTime,
            mode: .upcoming
        )
        start(densityLabel: densityLabel, state: state)
    }

    /// 같은 일정이면 갱신, 다른 일정이면 재시작 (깜빡임 방지). nil이면 종료.
    func sync(densityLabel: String, state: NowerLiveActivityAttributes.ContentState?) {
        guard let state = state else { end(); return }
        if let active = current, active.attributes.densityLabel == densityLabel,
           active.content.state.eventDate == state.eventDate {
            update(state) // 같은 일정 → 갱신만
        } else {
            start(densityLabel: densityLabel, state: state)
        }
    }
    #endif
}
#endif
