//
//  EventManager.swift
//  Nower
//
//  Created by 신종원 on 4/12/25.
//

import Foundation

class EventManager {
    static let shared = EventManager()

    private let key = "SavedTodos"
    private let store = NSUbiquitousKeyValueStore.default

    private(set) var todos: [TodoItem] = []

    private init() {
        loadTodos()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(icloudDidUpdate),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    func addTodo(_ todo: TodoItem) {
        todos.append(todo)
        saveTodos()
    }

    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }

    func todos(on date: Date) -> [TodoItem] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return todos.filter { $0.date == dateString }
    }

    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            store.set(encoded, forKey: key)
            store.synchronize()
        }
    }

    private func loadTodos() {
        guard let data = store.data(forKey: key),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            todos = []
            return
        }
        todos = decoded
    }

    @objc private func icloudDidUpdate(notification: Notification) {
        loadTodos()
        NotificationCenter.default.post(name: .init("TodosUpdated"), object: nil)
    }
}
