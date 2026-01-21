//
//  TodoRepositoryImpl.swift
//  Nower (macOS)
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// TodoRepository의 구현체
/// CloudSyncManager를 통해 실제 데이터 관리를 수행합니다.
final class TodoRepositoryImpl: TodoRepository {
    
    // MARK: - Properties
    private let cloudSyncManager: CloudSyncManager
    
    // MARK: - Initialization
    init(cloudSyncManager: CloudSyncManager = CloudSyncManager.shared) {
        self.cloudSyncManager = cloudSyncManager
    }
    
    // MARK: - TodoRepository Implementation
    
    func getAllTodos() -> [TodoItem] {
        return cloudSyncManager.getAllTodos()
    }
    
    func getTodos(for date: Date) -> [TodoItem] {
        return cloudSyncManager.getTodos(for: date)
    }
    
    func addTodo(_ todo: TodoItem) {
        cloudSyncManager.addTodo(todo)
    }
    
    func deleteTodo(_ todo: TodoItem) {
        cloudSyncManager.deleteTodo(todo)
    }
    
    func updateTodo(original: TodoItem, with updated: TodoItem) {
        cloudSyncManager.updateTodo(original: original, with: updated)
    }
    
    func forceSynchronize() {
        cloudSyncManager.forceSynchronize()
    }
}
