//
//  SyncStatusViewModel.swift
//  Nower-iOS
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import UIKit
#if canImport(NowerCore)
import NowerCore
#endif

final class SyncStatusViewModel {

    // MARK: - Properties

    private(set) var syncState: SyncState = .initial {
        didSet { onStateChange?(self) }
    }

    var onStateChange: ((SyncStatusViewModel) -> Void)?

    private var observer: NSObjectProtocol?
    private let syncStateObserver: SyncStateObserving

    // MARK: - Computed

    var iconName: String {
        switch syncState.phase {
        case .idle:       return "icloud"
        case .syncing:    return "arrow.triangle.2.circlepath.icloud"
        case .synced:     return "checkmark.icloud"
        case .failed:     return "exclamationmark.icloud"
        case .conflicted: return "exclamationmark.triangle"
        }
    }

    var iconColor: UIColor {
        switch syncState.phase {
        case .idle:       return .systemGray
        case .syncing:    return .systemBlue
        case .synced:     return .systemGreen
        case .failed:     return .systemOrange
        case .conflicted: return .systemRed
        }
    }

    var isAnimating: Bool {
        if case .syncing = syncState.phase { return true }
        return false
    }

    var shouldShowAlert: Bool {
        if case .failed = syncState.phase { return true }
        return false
    }

    var shouldShowConflicts: Bool {
        if case .conflicted = syncState.phase { return true }
        return false
    }

    var isVisible: Bool {
        switch syncState.phase {
        case .idle, .synced: return false
        case .syncing, .failed, .conflicted: return true
        }
    }

    var conflictCount: Int {
        syncState.conflicts.count
    }

    var lastSyncedText: String? {
        guard let date = syncState.lastSyncDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return "마지막 동기화: \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    var accessibilityLabel: String {
        switch syncState.phase {
        case .idle:       return "동기화 대기 중"
        case .syncing:    return "iCloud와 동기화 중"
        case .synced:     return "동기화 완료"
        case .failed:     return "동기화 문제 — 탭하여 재시도"
        case .conflicted: return "일정 충돌 \(syncState.conflicts.count)건 — 탭하여 해결"
        }
    }

    // MARK: - Initialization

    init(syncStateObserver: SyncStateObserving) {
        self.syncStateObserver = syncStateObserver
        startObserving()
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    func retrySync() {
        syncStateObserver.retrySync()
    }

    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) {
        syncStateObserver.resolveConflict(conflict, resolution: resolution)
    }

    func resolveAllConflicts(resolution: ConflictResolution) {
        syncStateObserver.resolveAllConflicts(resolution: resolution)
    }

    // MARK: - Private

    private func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: .syncStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let state = notification.userInfo?["state"] as? SyncState else { return }
            self?.syncState = state
        }
    }
}
