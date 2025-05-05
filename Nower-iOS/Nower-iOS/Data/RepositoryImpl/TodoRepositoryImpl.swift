//
//  TodoRepositoryImpl.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation

final class TodoRepositoryImpl: TodoRepository {
    private var todoStorage: [TodoItem] = []
    private let store = NSUbiquitousKeyValueStore.default

    init() {
        loadFromiCloud()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleiCloudUpdate),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    func fetchTodos(on date: Date) -> [TodoItem] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return todoStorage.filter { $0.date == key }
    }

    func addTodo(_ todo: TodoItem) {
        todoStorage.append(todo)
        saveToiCloud()
    }

    func deleteTodo(_ todo: TodoItem) {
        todoStorage.removeAll { $0.id == todo.id }
        saveToiCloud()
    }

    func updateTodo(_ original: TodoItem, with updated: TodoItem) {
        if let index = todoStorage.firstIndex(where: { $0.id == original.id }) {
            todoStorage[index] = updated
            saveToiCloud()
        }
    }

    func allTodos() -> [TodoItem] {
        return todoStorage
    }

    // MARK: - iCloud 연동

    private let iCloudKey = "SavedTodos"

    private func saveToiCloud() {
        let encoded = todoStorage.compactMap { try? JSONEncoder().encode($0) }
        store.set(encoded, forKey: iCloudKey)
        store.synchronize()
    }

    func loadFromiCloud() {
        guard let data = store.data(forKey: iCloudKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            todoStorage = []
            return
        }
        todoStorage = decoded
        print("iCloud에서 불러온 데이터")
    }

    @objc private func handleiCloudUpdate(_ notification: Notification) {
        print("📥 iCloud 동기화 감지됨 - 일정 로드")
        loadFromiCloud()
        NotificationCenter.default.post(name: .init("TodosUpdated"), object: nil)
    }
}
