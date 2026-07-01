//
//  DepartureNudgeManager.swift
//  Nower-Shared
//
//  Created by AI Assistant on 6/17/26.
//  Copyright © 2026 Nower. All rights reserved.
//

import Foundation
import NowerCore

/// 출발 알림 오케스트레이터.
/// 일정 텍스트 → 저장 장소 매칭 → 출발지 결정 → ETA 산출 → 출발 알림 시각 계산 → 예약을 묶습니다.
///
/// 출발 알림 = 약속시간 − ETA(보수적) − 준비버퍼 − 안전여유
final class DepartureNudgeManager {
    static let shared = DepartureNudgeManager()

    private let places: SavedPlacesManager
    private let directions: DirectionsProvider
    private let notifications: LocalNotificationManager

    init(
        places: SavedPlacesManager = .shared,
        directions: DirectionsProvider = KakaoDirectionsProvider(),
        notifications: LocalNotificationManager = .shared
    ) {
        self.places = places
        self.directions = directions
        self.notifications = notifications
    }

    // MARK: - Public

    /// 전체 일정의 출발 알림을 다시 계산·예약합니다.
    func refreshAll(todos: [TodoItem]) async {
        for todo in todos {
            await scheduleNudge(for: todo)
        }
    }

    /// 단일 일정의 출발 알림을 예약합니다.
    /// 매칭/좌표/시간 조건을 못 맞추면 조용히 건너뜁니다(에러 없음).
    /// - Returns: 실제로 예약했으면 true.
    @discardableResult
    func scheduleNudge(for todo: TodoItem) async -> Bool {
        // 기존 출발 알림 제거(중복 방지)
        notifications.cancelDepartureNotification(for: todo.id)

        guard let arrival = todo.scheduledDateTime, arrival > Date() else { return false }

        let settings = places.currentSettings()

        // 일정 텍스트 → 알림 대상 목적지 매칭
        guard let destination = settings.matchPlace(for: todo.text) else { return false }

        // 출발지 결정 (모호한 귀가 케이스는 V1 제외)
        guard let origin = resolveOrigin(destination: destination, settings: settings),
              origin.hasCoordinate,
              origin.id != destination.id,
              let oLat = origin.latitude, let oLng = origin.longitude,
              let dLat = destination.latitude, let dLng = destination.longitude
        else { return false }

        // ETA 산출 (차 + 대중교통)
        let eta = await directions.estimate(fromLat: oLat, fromLng: oLng, toLat: dLat, toLng: dLng)
        guard let travelMinutes = eta.conservativeMinutes else { return false }

        // 출발 알림 시각 = 약속시간 − ETA − 준비버퍼 − 안전여유
        let leadMinutes = travelMinutes + settings.defaultBufferMinutes + settings.safetyMarginMinutes
        let fireDate = arrival.addingTimeInterval(-Double(leadMinutes) * 60)
        guard fireDate > Date() else { return false }

        let body = makeBody(destination: destination, eta: eta, fireDate: fireDate)
        notifications.scheduleDepartureNotification(
            todoId: todo.id,
            body: body,
            fireDate: fireDate,
            origin: (lat: oLat, lng: oLng),
            destination: (lat: dLat, lng: dLng),
            destinationName: destination.name
        )
        return true
    }

    /// 일정의 출발 알림을 취소합니다.
    func cancel(for todoId: UUID) {
        notifications.cancelDepartureNotification(for: todoId)
    }

    // MARK: - 미매칭 1회 권유 (US-B2)

    private static let didSuggestSetupKey = "DepartureNudge.didSuggestSetup"

    /// 위치 설정 권유를 이미 한 번 띄웠는지.
    var hasSuggestedSetup: Bool {
        UserDefaults.standard.bool(forKey: Self.didSuggestSetupKey)
    }

    /// 권유를 띄웠다고 표시합니다. 이후 다시 권유하지 않습니다(무시/수락 무관).
    func markSetupSuggested() {
        UserDefaults.standard.set(true, forKey: Self.didSuggestSetupKey)
    }

    // MARK: - 준비 버퍼 시드 (US-E1)

    private static let didSeedBufferKey = "DepartureNudge.didSeedBuffer"

    /// 준비 버퍼를 한 번이라도 대화로 물어봤는지.
    var hasSeededBuffer: Bool {
        UserDefaults.standard.bool(forKey: Self.didSeedBufferKey)
    }

    /// 버퍼를 물어봤다고 표시합니다. 이후 다시 묻지 않습니다(응답/스킵 무관).
    func markBufferSeeded() {
        UserDefaults.standard.set(true, forKey: Self.didSeedBufferKey)
    }

    /// 이 일정이 "위치를 넣으면 출발 알림을 받을 수 있는데 슬롯이 비어 있는" 경우인지 판단합니다.
    /// 권유가 필요하면 비어 있는 고정 슬롯 종류를, 아니면 nil을 반환합니다.
    /// - 이미 한 번 권유했거나, 이미 알림이 잡히는 일정이면 nil.
    func setupSuggestion(for todo: TodoItem) -> PlaceKind? {
        guard !hasSuggestedSetup else { return nil }
        guard let arrival = todo.scheduledDateTime, arrival > Date() else { return nil }

        let settings = places.currentSettings()
        // 이미 매칭되는(좌표 있는) 장소가 있으면 알림이 잡히므로 권유 불필요.
        if settings.matchPlace(for: todo.text) != nil { return nil }

        // 회사를 집보다 우선해, 텍스트가 빈 고정 슬롯의 별칭과 맞는 첫 슬롯을 찾는다.
        for kind in [PlaceKind.work, .home] {
            guard let slot = settings.fixedPlace(kind),
                  !slot.hasCoordinate,
                  slot.matches(eventText: todo.text) else { continue }
            return kind
        }
        return nil
    }

    // MARK: - Private

    /// 출발지를 결정합니다.
    /// - 귀가(목적지=집): 출발지가 모호(회사→집 자동 가정 금지)하므로 V1 자동 예약 제외.
    /// - 그 외(출근/회사/기타): 출근 의존규칙에 따라 집에서 출발한다고 가정.
    private func resolveOrigin(destination: SavedPlace, settings: DepartureSettings) -> SavedPlace? {
        if destination.kind == .home {
            return nil // 귀가 케이스: 런타임 확인 필요 → V2
        }
        // 출근 의존규칙: 회사/기타 목적지는 집에서 출발한다고 가정
        guard settings.commuteOriginIsHome else { return nil }
        return settings.fixedPlace(.home)
    }

    /// 알림 본문 문구를 만듭니다.
    /// 예: "회사까지 차로 35분, 대중교통 48분 소요 예정. 현재 7시 30분, 일어나서 준비하셔야 합니다."
    private func makeBody(destination: SavedPlace, eta: ETAResult, fireDate: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let clock = String(format: "%d시 %02d분", hour, minute)
        return "\(destination.name)까지 \(eta.travelPhrase()) 소요 예정. 현재 \(clock), 일어나서 준비하셔야 합니다."
    }
}
