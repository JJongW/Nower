//
//  SavedPlacesManager.swift
//  Nower-Shared
//
//  Created by AI Assistant on 6/16/26.
//  Copyright © 2026 Nower. All rights reserved.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// 출발 알림 설정(저장 장소 + 기본값)을 iCloud에 저장·관리하는 매니저.
/// CloudSyncManager와 동일한 NSUbiquitousKeyValueStore 패턴을 따릅니다.
final class SavedPlacesManager {
    static let shared = SavedPlacesManager()

    // MARK: - Properties
    private let store = NSUbiquitousKeyValueStore.default
    private let settingsKey = "DepartureSettings"
    private var cached: DepartureSettings = .initial
    private let queue = DispatchQueue(label: "com.nower.savedplaces", qos: .userInitiated)

    // MARK: - Notifications
    static let didUpdateNotification = Notification.Name("SavedPlacesManager.didUpdate")

    // MARK: - Alias 충돌 결과
    enum AliasResult: Equatable {
        case ok
        case conflict(owner: String) // 충돌난 별칭을 이미 가진 장소 이름
    }

    // MARK: - Init
    private init() {
        setupObserver()
        load()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 조회

    /// 현재 설정 전체를 반환합니다.
    func currentSettings() -> DepartureSettings {
        queue.sync { cached }
    }

    /// 저장 장소 목록을 반환합니다.
    func allPlaces() -> [SavedPlace] {
        queue.sync { cached.places }
    }

    /// 고정 슬롯(집/회사)을 반환합니다.
    func fixedPlace(_ kind: PlaceKind) -> SavedPlace? {
        queue.sync { cached.fixedPlace(kind) }
    }

    /// 일정 텍스트에 매칭되는 알림 대상 장소를 찾습니다.
    func matchPlace(for eventText: String) -> SavedPlace? {
        queue.sync { cached.matchPlace(for: eventText) }
    }

    // MARK: - 장소 수정

    /// 고정 슬롯(집/회사)의 좌표·주소를 설정합니다.
    func updateFixedCoordinate(_ kind: PlaceKind, latitude: Double, longitude: Double, address: String?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let index = self.cached.places.firstIndex(where: { $0.kind == kind }) else { return }
            self.cached.places[index].latitude = latitude
            self.cached.places[index].longitude = longitude
            self.cached.places[index].address = address
            self.persist()
        }
    }

    /// 고정 슬롯의 좌표를 비웁니다(알림 비활성).
    func clearFixedCoordinate(_ kind: PlaceKind) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let index = self.cached.places.firstIndex(where: { $0.kind == kind }) else { return }
            self.cached.places[index].latitude = nil
            self.cached.places[index].longitude = nil
            self.cached.places[index].address = nil
            self.persist()
        }
    }

    /// 자유 장소를 추가합니다. V1에서는 nudgeEnabled = false(저장만).
    /// 별칭이 다른 장소와 충돌하면 추가하지 않고 conflict를 반환합니다.
    @discardableResult
    func addCustomPlace(name: String, latitude: Double?, longitude: Double?, address: String?, aliases: [String]) -> AliasResult {
        queue.sync {
            if let owner = conflictingOwner(for: aliases, excluding: nil) {
                return .conflict(owner: owner)
            }
            let place = SavedPlace(
                kind: .custom,
                name: name,
                latitude: latitude,
                longitude: longitude,
                address: address,
                aliases: aliases,
                nudgeEnabled: false
            )
            cached.places.append(place)
            persist()
            return .ok
        }
    }

    /// 장소의 별칭을 교체합니다. 충돌 시 거부합니다.
    @discardableResult
    func setAliases(_ aliases: [String], for placeID: UUID) -> AliasResult {
        queue.sync {
            if let owner = conflictingOwner(for: aliases, excluding: placeID) {
                return .conflict(owner: owner)
            }
            guard let index = cached.places.firstIndex(where: { $0.id == placeID }) else { return .ok }
            cached.places[index].aliases = aliases
            persist()
            return .ok
        }
    }

    /// 자유 장소를 삭제합니다. 고정 슬롯은 삭제 불가(좌표만 비울 수 있음).
    func removeCustomPlace(_ placeID: UUID) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.cached.places.removeAll { $0.id == placeID && $0.kind == .custom }
            self.persist()
        }
    }

    // MARK: - 기본값 수정

    func setDefaultBuffer(minutes: Int) {
        queue.async { [weak self] in
            self?.cached.defaultBufferMinutes = max(0, minutes)
            self?.persist()
        }
    }

    func setSafetyMargin(minutes: Int) {
        queue.async { [weak self] in
            self?.cached.safetyMarginMinutes = max(0, minutes)
            self?.persist()
        }
    }

    func setCommuteOriginIsHome(_ enabled: Bool) {
        queue.async { [weak self] in
            self?.cached.commuteOriginIsHome = enabled
            self?.persist()
        }
    }

    // MARK: - Private

    /// 주어진 별칭들이 (excluding을 제외한) 다른 장소의 별칭과 충돌하는지 검사합니다.
    /// queue 내부에서 호출합니다.
    private func conflictingOwner(for aliases: [String], excluding: UUID?) -> String? {
        let incoming = Set(aliases.map { SavedPlace.normalize($0) }.filter { !$0.isEmpty })
        for place in cached.places where place.id != excluding {
            for alias in place.aliases {
                if incoming.contains(SavedPlace.normalize(alias)) {
                    return place.name
                }
            }
        }
        return nil
    }

    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleiCloudChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    @objc private func handleiCloudChange(_ notification: Notification) {
        load()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.didUpdateNotification, object: nil)
        }
    }

    /// iCloud에서 설정을 로드합니다. 없거나 깨졌으면 초기 설정으로 시작합니다.
    private func load() {
        queue.sync {
            guard let data = store.data(forKey: settingsKey) else {
                cached = .initial
                return
            }
            do {
                var loaded = try JSONDecoder().decode(DepartureSettings.self, from: data)
                loaded = Self.ensureFixedSlots(loaded)
                cached = loaded
            } catch {
                cached = .initial
            }
        }
    }

    /// 집·회사 고정 슬롯이 항상 존재하도록 보정합니다.
    private static func ensureFixedSlots(_ settings: DepartureSettings) -> DepartureSettings {
        var result = settings
        if result.fixedPlace(.home) == nil {
            result.places.insert(.emptyFixed(.home), at: 0)
        }
        if result.fixedPlace(.work) == nil {
            result.places.insert(.emptyFixed(.work), at: 1)
        }
        return result
    }

    /// 현재 캐시를 iCloud에 저장합니다. queue 내부에서 호출합니다.
    private func persist() {
        do {
            let data = try JSONEncoder().encode(cached)
            store.set(data, forKey: settingsKey)
            store.synchronize()
        } catch {
            return
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.didUpdateNotification, object: nil)
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }
}
