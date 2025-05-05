//
//  EventModel.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/11/25.
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
        loadTodos()

        let serverData = store.data(forKey: key)
        var serverTodos: [TodoItem] = []
        if let data = serverData, let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            serverTodos = decoded
        }

        var mergedTodos = serverTodos
        mergedTodos.append(todo)

        let uniqueTodos = Array(Set(mergedTodos))

        todos = uniqueTodos
        saveTodos()
    }

    func deleteTodo(_ todo: TodoItem) {
        loadTodos()

        var serverTodos: [TodoItem] = []
        if let data = store.data(forKey: key),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            serverTodos = decoded
        }

        var mergedTodos = serverTodos + todos

        mergedTodos.removeAll { $0.id == todo.id }

        let uniqueTodos = Array(Set(mergedTodos))

        todos = uniqueTodos
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
            print("✅ iCloud에 넣은 데이터: \(todos)")
        }
    }

    func loadTodos() {
        guard let data = store.data(forKey: key),
                let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
              todos = []
              print("❌ iCloud에서 불러온 데이터 없음")
              return
          }
          todos = decoded
          print("✅ iCloud에서 불러온 데이터: \(todos)")
    }

    @objc private func icloudDidUpdate(notification: Notification) {
        loadTodos()
        NotificationCenter.default.post(name: .init("TodosUpdated"), object: nil)
    }
}
