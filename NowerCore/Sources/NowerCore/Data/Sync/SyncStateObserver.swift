//
//  SyncStateObserver.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

// MARK: - Sync Data Source Protocol

/// 레거시 CloudSyncManager와의 브릿지를 위한 데이터 소스 프로토콜
public protocol SyncDataSource: AnyObject {
    /// 현재 서버에서 로드된 모든 항목의 스냅샷 정보를 반환합니다.
    func allItemSnapshots() -> [SyncItemSnapshot]
    /// 마지막 쓰기 이후의 로컬 스냅샷을 반환합니다.
    func localItemSnapshots() -> [UUID: SyncItemSnapshot]
    /// 보류 중인 로컬 변경 ID를 반환합니다.
    func pendingChangeIDs() -> Set<UUID>
    /// 보류 중인 변경을 초기화합니다.
    func clearPendingChangeIDs()
    /// 충돌 해결을 적용합니다.
    func applyConflictResolution(_ resolution: ConflictResolution, for conflict: SyncConflict)
    /// 강제 동기화를 수행합니다.
    func performForceSynchronize()
}

/// 동기화 항목 스냅샷 (플랫폼 독립적)
public struct SyncItemSnapshot: Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let colorName: String
    public let date: String
    public let modifiedAt: Date

    public init(id: UUID, title: String, colorName: String, date: String, modifiedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.colorName = colorName
        self.date = date
        self.modifiedAt = modifiedAt
    }
}

// MARK: - SyncStateObserving Protocol

public protocol SyncStateObserving: AnyObject {
    var currentState: SyncState { get }
    func startObserving()
    func stopObserving()
    func retrySync()
    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution)
    func resolveAllConflicts(resolution: ConflictResolution)
}

// MARK: - DefaultSyncStateObserver

public final class DefaultSyncStateObserver: SyncStateObserving {

    // MARK: - Properties

    private(set) public var currentState: SyncState = .initial {
        didSet {
            guard currentState != oldValue else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .syncStateDidChange,
                    object: nil,
                    userInfo: ["state": self.currentState]
                )
            }
        }
    }

    private let syncManager: SyncManager
    private weak var dataSource: SyncDataSource?
    private let retryManager = SyncRetryManager()

    private var observers: [NSObjectProtocol] = []
    private var idleTimer: DispatchSourceTimer?

    // MARK: - Initialization

    public init(syncManager: SyncManager, dataSource: SyncDataSource? = nil) {
        self.syncManager = syncManager
        self.dataSource = dataSource
    }

    deinit {
        stopObserving()
    }

    // MARK: - Public Methods

    public func startObserving() {
        stopObserving()

        let center = NotificationCenter.default

        observers.append(
            center.addObserver(forName: .syncDidStart, object: nil, queue: .main) { [weak self] _ in
                self?.handleSyncDidStart()
            }
        )

        observers.append(
            center.addObserver(forName: .syncDidComplete, object: nil, queue: .main) { [weak self] _ in
                self?.handleSyncDidComplete()
            }
        )

        observers.append(
            center.addObserver(forName: .syncDidFail, object: nil, queue: .main) { [weak self] notification in
                let error = notification.userInfo?["error"] as? NowerError
                    ?? .syncFailed(message: "알 수 없는 오류")
                self?.handleSyncDidFail(error: error)
            }
        )

        observers.append(
            center.addObserver(forName: .eventsDidUpdate, object: nil, queue: .main) { [weak self] _ in
                self?.handleServerChange()
            }
        )

        // CloudSyncManager.todosDidUpdateNotification
        observers.append(
            center.addObserver(
                forName: Notification.Name("CloudSyncManager.todosDidUpdate"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleServerChange()
            }
        )
    }

    public func stopObserving() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        retryManager.cancel()
        cancelIdleTimer()
    }

    public func retrySync() {
        retryManager.reset()
        currentState = SyncState(
            phase: .syncing,
            lastSyncDate: currentState.lastSyncDate,
            pendingChangeCount: currentState.pendingChangeCount
        )
        if let ds = dataSource {
            ds.performForceSynchronize()
        } else {
            syncManager.forceSynchronize()
        }
    }

    public func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) {
        dataSource?.applyConflictResolution(resolution, for: conflict)
        refreshState()
    }

    public func resolveAllConflicts(resolution: ConflictResolution) {
        let conflicts = currentState.conflicts
        for conflict in conflicts {
            dataSource?.applyConflictResolution(resolution, for: conflict)
        }
        refreshState()
    }

    // MARK: - State Handlers

    private func handleSyncDidStart() {
        cancelIdleTimer()
        currentState = SyncState(
            phase: .syncing,
            lastSyncDate: currentState.lastSyncDate,
            pendingChangeCount: currentState.pendingChangeCount
        )
    }

    private func handleSyncDidComplete() {
        retryManager.reset()
        let now = Date()

        // Check for conflicts
        let conflicts = detectConflicts()
        if !conflicts.isEmpty {
            currentState = SyncState(
                phase: .conflicted,
                lastSyncDate: now,
                pendingChangeCount: dataSource?.pendingChangeIDs().count ?? 0,
                conflicts: conflicts
            )
        } else {
            dataSource?.clearPendingChangeIDs()
            currentState = SyncState(
                phase: .synced,
                lastSyncDate: now,
                pendingChangeCount: 0
            )
            scheduleIdleTransition()
        }
    }

    private func handleSyncDidFail(error: NowerError) {
        cancelIdleTimer()
        let pendingCount = dataSource?.pendingChangeIDs().count ?? currentState.pendingChangeCount

        currentState = SyncState(
            phase: .failed(error),
            lastSyncDate: currentState.lastSyncDate,
            pendingChangeCount: pendingCount
        )

        // Schedule retry
        retryManager.scheduleRetry { [weak self] in
            DispatchQueue.main.async {
                self?.retrySync()
            }
        }
    }

    private func handleServerChange() {
        // Only detect conflicts if we have pending local changes
        guard let ds = dataSource, !ds.pendingChangeIDs().isEmpty else { return }

        let conflicts = detectConflicts()
        if !conflicts.isEmpty {
            currentState = SyncState(
                phase: .conflicted,
                lastSyncDate: currentState.lastSyncDate,
                pendingChangeCount: ds.pendingChangeIDs().count,
                conflicts: conflicts
            )
        }
    }

    // MARK: - Conflict Detection

    private func detectConflicts() -> [SyncConflict] {
        guard let ds = dataSource else { return [] }

        let serverItems = ds.allItemSnapshots()
        let localSnapshot = ds.localItemSnapshots()
        let pending = ds.pendingChangeIDs()

        let serverMap = Dictionary(uniqueKeysWithValues: serverItems.map { ($0.id, $0) })
        var conflicts: [SyncConflict] = []

        for uuid in pending {
            guard let localVersion = localSnapshot[uuid] else { continue }

            if let serverVersion = serverMap[uuid] {
                // Both exist — check if they differ
                if localVersion.title != serverVersion.title
                    || localVersion.colorName != serverVersion.colorName
                    || localVersion.date != serverVersion.date {
                    conflicts.append(SyncConflict(
                        id: uuid,
                        localTitle: localVersion.title,
                        localColorName: localVersion.colorName,
                        localDate: localVersion.date,
                        localModifiedAt: localVersion.modifiedAt,
                        remoteTitle: serverVersion.title,
                        remoteColorName: serverVersion.colorName,
                        remoteDate: serverVersion.date,
                        remoteModifiedAt: serverVersion.modifiedAt
                    ))
                }
            } else {
                // Local has changes but remote deleted
                conflicts.append(SyncConflict(
                    id: uuid,
                    localTitle: localVersion.title,
                    localColorName: localVersion.colorName,
                    localDate: localVersion.date,
                    localModifiedAt: localVersion.modifiedAt,
                    remoteTitle: "(삭제됨)",
                    remoteColorName: "",
                    remoteDate: "",
                    remoteModifiedAt: Date()
                ))
            }
        }

        return conflicts
    }

    // MARK: - Idle Timer

    private func scheduleIdleTransition() {
        cancelIdleTimer()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 3.0)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            if case .synced = self.currentState.phase {
                self.currentState = SyncState(
                    phase: .idle,
                    lastSyncDate: self.currentState.lastSyncDate,
                    pendingChangeCount: 0
                )
            }
            self.idleTimer = nil
        }
        timer.resume()
        idleTimer = timer
    }

    private func cancelIdleTimer() {
        idleTimer?.cancel()
        idleTimer = nil
    }

    // MARK: - Refresh

    private func refreshState() {
        let conflicts = detectConflicts()
        if conflicts.isEmpty {
            dataSource?.clearPendingChangeIDs()
            currentState = SyncState(
                phase: .synced,
                lastSyncDate: Date(),
                pendingChangeCount: 0
            )
            scheduleIdleTransition()
        } else {
            currentState = SyncState(
                phase: .conflicted,
                lastSyncDate: currentState.lastSyncDate,
                pendingChangeCount: dataSource?.pendingChangeIDs().count ?? 0,
                conflicts: conflicts
            )
        }
    }
}
