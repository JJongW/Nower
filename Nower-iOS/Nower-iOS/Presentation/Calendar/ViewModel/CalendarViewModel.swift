//
//  TodoViewModel.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation
import Combine

final class CalendarViewModel: ObservableObject {
    private let addTodoUseCase: AddTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    private let updateTodoUseCase: UpdateTodoUseCase
    private let getTodosByDateUseCase: GetTodosByDateUseCase
    private let loadAllTodosUseCase: LoadAllTodosUseCase
    private let holidayUseCase: HolidayUseCase

    @Published var todosByDate: [String: [TodoItem]] = [:]
    @Published var selectedDate: Date?
    @Published var todoText: String = ""
    @Published var isRepeating: Bool = false
    @Published var selectedColorName: String = "default"
    @Published var selectedColor: String = "skyblue"

    init(
        addTodoUseCase: AddTodoUseCase,
        deleteTodoUseCase: DeleteTodoUseCase,
        updateTodoUseCase: UpdateTodoUseCase,
        getTodosByDateUseCase: GetTodosByDateUseCase,
        loadAllTodosUseCase: LoadAllTodosUseCase,
        holidayUseCase: HolidayUseCase
    ) {
        self.addTodoUseCase = addTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.updateTodoUseCase = updateTodoUseCase
        self.getTodosByDateUseCase = getTodosByDateUseCase
        self.loadAllTodosUseCase = loadAllTodosUseCase
        self.holidayUseCase = holidayUseCase

        loadAllTodos()
    }

    func loadAllTodos() {
        NSUbiquitousKeyValueStore.default.synchronize()

        todosByDate = [:]
        let allTodos = loadAllTodosUseCase.execute()
        print("📦 allTodos:", allTodos)
        for todo in allTodos {
            todosByDate[todo.date, default: []].append(todo)
        }
    }

    func todos(for date: Date) -> [TodoItem] {
        let key = date.toDateString()
        return todosByDate[key] ?? []
    }

    func holidayName(for date: Date) -> String? {
        return holidayUseCase.holidayName(for: date)
    }

    func preloadHolidays(baseDate: Date) {
        holidayUseCase.preloadAdjacentMonths(baseDate: baseDate, completion: nil)
    }

    func addTodo() {
        guard let date = selectedDate, !todoText.isEmpty else { return }
        let newTodo = TodoItem(text: todoText, isRepeating: isRepeating, date: date.toDateString(), colorName: selectedColorName)
        addTodoUseCase.execute(todo: newTodo)
        NSUbiquitousKeyValueStore.default.synchronize()
        loadAllTodos()
        NotificationCenter.default.post(name: .todosUpdated, object: nil)
    }

    func deleteTodo(_ todo: TodoItem) {
        deleteTodoUseCase.execute(todo: todo)
        NSUbiquitousKeyValueStore.default.synchronize()
        loadAllTodos()
        NotificationCenter.default.post(name: .todosUpdated, object: nil)
    }

    func updateTodo(original: TodoItem, updatedText: String, updatedColor: String) {
        let updatedTodo = TodoItem(text: updatedText, isRepeating: isRepeating, date: original.date, colorName: updatedColor)
        updateTodoUseCase.execute(original: original, updated: updatedTodo)
        NSUbiquitousKeyValueStore.default.synchronize()
        loadAllTodos()
        NotificationCenter.default.post(name: .todosUpdated, object: nil)
    }

    func debugPrintICloudTodos() {
        NSUbiquitousKeyValueStore.default.synchronize()

        print("🔍 [iCloud] todos 확인 시작")

        guard let saved = NSUbiquitousKeyValueStore.default.array(forKey: "SavedTodos") as? [Data] else {
            print("⚠️ iCloud 저장소에서 'todos' 키에 해당하는 배열이 없음")
            return
        }

        print("✅ iCloud에 저장된 TodoItem 총 \(saved.count)개")

        for (index, data) in saved.enumerated() {
            do {
                let item = try JSONDecoder().decode(TodoItem.self, from: data)
                print("🔸 [\(index)] \(item.text) | \(item.date) | \(item.colorName) | 반복: \(item.isRepeating)")
            } catch {
                print("❌ [\(index)] 디코딩 실패: \(error)")
            }
        }
    }
}
