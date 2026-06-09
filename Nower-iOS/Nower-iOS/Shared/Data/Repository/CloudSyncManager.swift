//
//  CloudSyncManager.swift
//  Nower-Shared
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(NowerCore)
import NowerCore
#endif

/// iCloud 동기화를 담당하는 공통 매니저
/// MacOS와 iOS에서 동일한 동기화 로직을 사용하여 데이터 일관성을 보장합니다.
final class CloudSyncManager {
    static let shared = CloudSyncManager()
    
    // MARK: - Properties
    private let store = NSUbiquitousKeyValueStore.default
    private let todosKey = "SavedTodos"
    private var cachedTodos: [TodoItem] = []
    private let syncQueue = DispatchQueue(label: "com.nower.sync", qos: .userInitiated)

    // MARK: - Snapshot Tracking
    private var localSnapshot: [UUID: TodoItem] = [:]
    private var pendingLocalChanges: Set<UUID> = []

    // MARK: - Notifications
    static let todosDidUpdateNotification = Notification.Name("CloudSyncManager.todosDidUpdate")
    private static let syncDidStartName = Notification.Name("NowerCore.syncDidStart")
    private static let syncDidCompleteName = Notification.Name("NowerCore.syncDidComplete")
    private static let syncDidFailName = Notification.Name("NowerCore.syncDidFail")
    
    // MARK: - Initialization
    private init() {
        setupiCloudObserver()
        loadTodos()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 모든 Todo를 조회합니다.
    /// - Returns: 모든 Todo 목록
    func getAllTodos() -> [TodoItem] {
        syncQueue.sync {
            return cachedTodos
        }
    }
    
    /// 특정 날짜의 Todo를 조회합니다.
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 Todo 목록
    func getTodos(for date: Date) -> [TodoItem] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        return syncQueue.sync {
            return cachedTodos.filter { $0.date == dateString }
        }
    }
    
    /// Todo를 추가합니다.
    /// - Parameter todo: 추가할 Todo
    func addTodo(_ todo: TodoItem) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }

            // 중복 방지: 같은 ID가 이미 존재하는지 확인
            if !self.cachedTodos.contains(where: { $0.id == todo.id }) {
                self.cachedTodos.append(todo)
                self.pendingLocalChanges.insert(todo.id)
                self.saveToiCloud()
                self.updateSnapshot()

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.todosDidUpdateNotification, object: nil)
                }
            }
        }
    }
    
    /// Todo를 삭제합니다.
    /// - Parameter todo: 삭제할 Todo
    func deleteTodo(_ todo: TodoItem) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }

            self.cachedTodos.removeAll { $0.id == todo.id }
            self.pendingLocalChanges.insert(todo.id)
            self.saveToiCloud()
            self.updateSnapshot()

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.todosDidUpdateNotification, object: nil)
            }
        }
    }
    
    /// Todo를 업데이트합니다.
    /// - Parameters:
    ///   - original: 원본 Todo
    ///   - updated: 업데이트된 Todo
    func updateTodo(original: TodoItem, with updated: TodoItem) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }

            if let index = self.cachedTodos.firstIndex(where: { $0.id == original.id }) {
                // 업데이트된 Todo의 ID를 원본과 동일하게 유지
                var updatedTodo = updated
                updatedTodo.id = original.id
                self.cachedTodos[index] = updatedTodo
                self.pendingLocalChanges.insert(original.id)
                self.saveToiCloud()
                self.updateSnapshot()

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.todosDidUpdateNotification, object: nil)
                }
            }
        }
    }
    
    /// 수동으로 iCloud와 동기화를 수행합니다.
    func forceSynchronize() {
        store.synchronize()
        loadTodos()
    }

    // MARK: - Snapshot Access

    /// 마지막 성공적인 쓰기 이후의 로컬 스냅샷을 반환합니다.
    func getLocalSnapshot() -> [UUID: TodoItem] {
        syncQueue.sync { localSnapshot }
    }

    /// 마지막 서버 동기화 이후 로컬에서 변경된 항목 ID를 반환합니다.
    func getPendingChanges() -> Set<UUID> {
        syncQueue.sync { pendingLocalChanges }
    }

    /// 보류 중인 변경 사항을 초기화합니다.
    func clearPendingChanges() {
        syncQueue.async { [weak self] in
            self?.pendingLocalChanges.removeAll()
        }
    }

    #if canImport(NowerCore)
    /// 충돌 해결을 적용합니다.
    func applyResolution(_ resolution: ConflictResolution, for conflict: SyncConflict) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }

            switch resolution {
            case .keepLocal:
                // 로컬 버전 유지 — 스냅샷에서 복원하여 다시 저장
                if let localVersion = self.localSnapshot[conflict.id] {
                    if let index = self.cachedTodos.firstIndex(where: { $0.id == conflict.id }) {
                        self.cachedTodos[index] = localVersion
                    } else {
                        self.cachedTodos.append(localVersion)
                    }
                    self.saveToiCloud()
                }

            case .keepRemote:
                // 리모트 버전 유지 — 이미 cachedTodos에 반영됨, 스냅샷만 갱신
                break

            case .keepBoth:
                // 로컬 버전을 새 ID로 복제하여 추가
                if let localVersion = self.localSnapshot[conflict.id] {
                    let duplicated = TodoItem(
                        id: UUID(),
                        text: localVersion.text,
                        isRepeating: localVersion.isRepeating,
                        date: localVersion.date,
                        colorName: localVersion.colorName,
                        startDate: localVersion.startDate,
                        endDate: localVersion.endDate,
                        scheduledTime: localVersion.scheduledTime,
                        reminderMinutesBefore: localVersion.reminderMinutesBefore,
                        recurrenceInfo: localVersion.recurrenceInfo,
                        recurrenceExceptions: localVersion.recurrenceExceptions,
                        recurrenceSeriesId: localVersion.recurrenceSeriesId
                    )
                    self.cachedTodos.append(duplicated)
                    self.saveToiCloud()
                }
            }

            self.pendingLocalChanges.remove(conflict.id)
            self.updateSnapshot()

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.todosDidUpdateNotification, object: nil)
            }
        }
    }
    #endif
    
    // MARK: - Private Methods
    
    /// iCloud 변경 사항을 감지하는 옵저버를 설정합니다.
    private func setupiCloudObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleiCloudChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }
    
    /// iCloud 변경 사항을 처리합니다.
    @objc private func handleiCloudChange(_ notification: Notification) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.syncDidStartName, object: nil)
        }

        loadTodos()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.todosDidUpdateNotification, object: nil)
            NotificationCenter.default.post(name: Self.syncDidCompleteName, object: nil)
        }
    }
    
    /// iCloud에서 데이터를 로드합니다.
    private func loadTodos() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard let data = self.store.data(forKey: self.todosKey) else {
                self.cachedTodos = []
                return
            }

            do {
                let todos = try JSONDecoder().decode([TodoItem].self, from: data)
                self.cachedTodos = todos
            } catch {
                self.cachedTodos = []
            }
        }
    }
    
    /// 데이터를 iCloud에 저장합니다.
    private func saveToiCloud() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.syncDidStartName, object: nil)
        }

        do {
            let data = try JSONEncoder().encode(cachedTodos)
            store.set(data, forKey: todosKey)
            store.synchronize()

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.syncDidCompleteName, object: nil)

                // 위젯 타임라인 즉시 갱신
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
        } catch {
            let syncError: Error
            #if canImport(NowerCore)
            syncError = NowerError.encodingFailed
            #else
            syncError = error
            #endif

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Self.syncDidFailName,
                    object: nil,
                    userInfo: ["error": syncError]
                )
            }
        }
    }

    /// 로컬 스냅샷을 현재 캐시 상태로 갱신합니다. syncQueue 내부에서 호출합니다.
    private func updateSnapshot() {
        localSnapshot = Dictionary(uniqueKeysWithValues: cachedTodos.map { ($0.id, $0) })
    }
}

// MARK: - SyncDataSource
#if canImport(NowerCore)
extension CloudSyncManager: SyncDataSource {
    func allItemSnapshots() -> [SyncItemSnapshot] {
        getAllTodos().map {
            SyncItemSnapshot(id: $0.id, title: $0.text, colorName: $0.colorName, date: $0.date)
        }
    }

    func localItemSnapshots() -> [UUID: SyncItemSnapshot] {
        let snapshot = getLocalSnapshot()
        var result: [UUID: SyncItemSnapshot] = [:]
        for (id, item) in snapshot {
            result[id] = SyncItemSnapshot(id: id, title: item.text, colorName: item.colorName, date: item.date)
        }
        return result
    }

    func pendingChangeIDs() -> Set<UUID> {
        getPendingChanges()
    }

    func clearPendingChangeIDs() {
        clearPendingChanges()
    }

    func applyConflictResolution(_ resolution: ConflictResolution, for conflict: SyncConflict) {
        applyResolution(resolution, for: conflict)
    }

    func performForceSynchronize() {
        forceSynchronize()
    }
}
#endif
