//
//  TodoRepositoryImpl.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation

final class TodoRepositoryImpl: TodoRepository {
    // MARK: - Properties
    private let cloudSyncManager: CloudSyncManager
    
    // MARK: - Initialization
    init(cloudSyncManager: CloudSyncManager = CloudSyncManager.shared) {
        self.cloudSyncManager = cloudSyncManager
    }

    // MARK: - TodoRepository Implementation
    
    func fetchTodos(on date: Date) -> [TodoItem] {
        return cloudSyncManager.getTodos(for: date)
    }

    func addTodo(_ todo: TodoItem) {
        cloudSyncManager.addTodo(todo)
    }

    func deleteTodo(_ todo: TodoItem) {
        cloudSyncManager.deleteTodo(todo)
    }

    func updateTodo(_ original: TodoItem, with updated: TodoItem) {
        cloudSyncManager.updateTodo(original: original, with: updated)
    }

    func allTodos() -> [TodoItem] {
        return cloudSyncManager.getAllTodos()
    }



}
