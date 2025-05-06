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
        print("🧾 iCloud 내용(macOS):", NSUbiquitousKeyValueStore.default.dictionaryRepresentation)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(icloudDidUpdate),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
        print("")
    }

    func addTodo(_ todo: TodoItem) {
        loadTodos() // 최신 iCloud 데이터 불러오기

        // iCloud 서버에 있는 기존 데이터 읽기
        let serverData = store.data(forKey: key)
        var serverTodos: [TodoItem] = []
        if let data = serverData, let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            serverTodos = decoded
        }

        // 서버에 있던 데이터 + 현재 추가하려는 Todo 병합
        var mergedTodos = serverTodos
        mergedTodos.append(todo)

        // 중복 제거 (id 기준)
        let uniqueTodos = Array(Set(mergedTodos))

        todos = uniqueTodos
        saveTodos()
    }

    func deleteTodo(_ todo: TodoItem) {
        loadTodos()

        // 서버에 있는 기존 데이터 읽기
        var serverTodos: [TodoItem] = []
        if let data = store.data(forKey: key),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            serverTodos = decoded
        }

        // 서버 데이터와 현재 데이터 병합
        var mergedTodos = serverTodos + todos

        // 삭제할 TodoItem 제외
        mergedTodos.removeAll { $0.id == todo.id }

        // 중복 제거
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

    private func loadTodos() {
        guard let data = store.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([TodoItem].self,from: data) else {
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
