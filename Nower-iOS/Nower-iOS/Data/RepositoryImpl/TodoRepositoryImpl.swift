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
        loadFromiCloud()
        todoStorage.append(todo)
        saveToiCloud()
    }

    func deleteTodo(_ todo: TodoItem) {
        loadFromiCloud()
        todoStorage.removeAll { $0.id == todo.id }
        saveToiCloud()
    }

    func updateTodo(_ original: TodoItem, with updated: TodoItem) {
        loadFromiCloud()
        if let index = todoStorage.firstIndex(where: { $0.id == original.id }) {
            todoStorage[index] = updated
            saveToiCloud()
        }
    }

    func allTodos() -> [TodoItem] {
        print("🧾 현재 todoStorage 수:", todoStorage.count)
        return todoStorage
    }

    // MARK: - iCloud 연동

    private let iCloudKey = "SavedTodos"

    private func saveToiCloud() {
        do {
            let encoded = try JSONEncoder().encode(todoStorage)
            store.set(encoded, forKey: iCloudKey)
            store.synchronize()
            print("✅ iCloud 저장 완료: \(todoStorage.count)개")
        } catch {
            print("❌ 저장 실패:", error)
        }
    }

    func loadFromiCloud() {
        guard let data = store.data(forKey: iCloudKey) else {
            print("⚠️ 저장된 데이터 없음")
            todoStorage = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode([TodoItem].self, from: data)
            todoStorage = decoded
            print("✅ 불러오기 성공: \(decoded.count)개")
        } catch {
            print("❌ 디코딩 실패:", error)
            todoStorage = []
        }
    }

    @objc private func handleiCloudUpdate(_ notification: Notification) {
        print("📥 iCloud 동기화 감지됨")
        store.synchronize() // ✅ 수동 동기화
        loadFromiCloud()
        NotificationCenter.default.post(name: .init("TodosUpdated"), object: nil)
    }
}
