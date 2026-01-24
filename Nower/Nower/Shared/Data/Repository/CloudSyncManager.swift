//
//  CloudSyncManager.swift
//  Nower-Shared
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// iCloud 동기화를 담당하는 공통 매니저
/// MacOS와 iOS에서 동일한 동기화 로직을 사용하여 데이터 일관성을 보장합니다.
final class CloudSyncManager {
    static let shared = CloudSyncManager()
    
    // MARK: - Properties
    private let store = NSUbiquitousKeyValueStore.default
    private let todosKey = "SavedTodos"
    private var cachedTodos: [TodoItem] = []
    private let syncQueue = DispatchQueue(label: "com.nower.sync", qos: .userInitiated)
    
    // MARK: - Notifications
    static let todosDidUpdateNotification = Notification.Name("CloudSyncManager.todosDidUpdate")
    
    // MARK: - Initialization
    private init() {
        setupiCloudObserver()
        // 초기 로드는 비동기로 처리하여 초기화 블로킹 방지
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadTodos()
        }
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
                // 이미 syncQueue 내부이므로 직접 저장 (데드락 방지)
                self.saveToiCloudInternal()
                
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
            // 이미 syncQueue 내부이므로 직접 저장 (데드락 방지)
            self.saveToiCloudInternal()
            
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
                
                // 이미 syncQueue 내부이므로 직접 저장 (데드락 방지)
                self.saveToiCloudInternal()
                
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
        // loadTodos는 이미 비동기로 처리되므로 안전하게 호출 가능
        loadTodos()
        
        // 알림은 loadTodos 완료 후에 보내야 하므로, loadTodos 내부에서 처리하도록 변경
        // (현재는 loadTodos가 비동기이므로 별도 처리 불필요)
    }
    
    /// iCloud에서 데이터를 로드합니다.
    private func loadTodos() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 이미 syncQueue 내부에 있으므로 직접 접근 (데드락 방지)
            guard let data = self.store.data(forKey: self.todosKey) else {
                print("⚠️ [CloudSyncManager] iCloud에 저장된 데이터가 없습니다")
                self.cachedTodos = []
                
                // 데이터 로드 완료 후 알림 전송
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.todosDidUpdateNotification, object: nil)
                }
                return
            }
            
            do {
                let todos = try JSONDecoder().decode([TodoItem].self, from: data)
                self.cachedTodos = todos
                
                // 데이터 로드 완료 후 알림 전송
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.todosDidUpdateNotification, object: nil)
                }
            } catch {
                print("❌ [CloudSyncManager] 데이터 디코딩 실패: \(error)")
                self.cachedTodos = []
                
                // 에러 발생 시에도 알림 전송
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.todosDidUpdateNotification, object: nil)
                }
            }
        }
    }
    
    /// 데이터를 iCloud에 저장합니다. (외부에서 호출 시 사용)
    private func saveToiCloud() {
        // 동기화 큐 내에서 안전하게 데이터 복사
        let todosToSave = syncQueue.sync {
            return cachedTodos
        }
        
        do {
            let data = try JSONEncoder().encode(todosToSave)
            store.set(data, forKey: todosKey)
            store.synchronize()
        } catch {
            print("❌ [CloudSyncManager] 데이터 인코딩 실패: \(error)")
        }
    }
    
    /// 데이터를 iCloud에 저장합니다. (syncQueue 내부에서 호출 시 사용, 데드락 방지)
    private func saveToiCloudInternal() {
        // 이미 syncQueue 내부에 있으므로 직접 접근 (데드락 방지)
        do {
            let data = try JSONEncoder().encode(cachedTodos)
            store.set(data, forKey: todosKey)
            store.synchronize()
        } catch {
            print("❌ [CloudSyncManager] 데이터 인코딩 실패: \(error)")
        }
    }
}

// MARK: - Debugging
extension CloudSyncManager {
    /// 디버깅용 iCloud 상태를 출력합니다.
    func debugPrintStatus() {
        #if DEBUG
        print("🔍 [CloudSyncManager] 디버그 정보:")
        print("  - 캐시된 Todo 수: \(cachedTodos.count)")
        print("  - iCloud 동기화 상태: \(store.dictionaryRepresentation)")
        
        for (index, todo) in cachedTodos.enumerated() {
            print("  - [\(index)] \(todo.text) | \(todo.date) | \(todo.colorName)")
        }
        #endif
    }
}
