//
//  TodoViewModel.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation
import Combine

final class CalendarViewModel: ObservableObject {
    // MARK: - UseCases
    private let addTodoUseCase: AddTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    private let updateTodoUseCase: UpdateTodoUseCase
    private let getTodosByDateUseCase: GetTodosByDateUseCase
    private let loadAllTodosUseCase: LoadAllTodosUseCase

    // MARK: - Published Properties
    @Published var todosByDate: [String: [TodoItem]] = [:]
    @Published var selectedDate: Date?
    @Published var todoText: String = ""
    @Published var isRepeating: Bool = false
    @Published var selectedColorName: String = "skyblue"

    // MARK: - Init
    init(
        addTodoUseCase: AddTodoUseCase,
        deleteTodoUseCase: DeleteTodoUseCase,
        updateTodoUseCase: UpdateTodoUseCase,
        getTodosByDateUseCase: GetTodosByDateUseCase,
        loadAllTodosUseCase: LoadAllTodosUseCase
    ) {
        self.addTodoUseCase = addTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.updateTodoUseCase = updateTodoUseCase
        self.getTodosByDateUseCase = getTodosByDateUseCase
        self.loadAllTodosUseCase = loadAllTodosUseCase

        loadAllTodos()
    }

    // MARK: - Methods

    func loadAllTodos() {
        todosByDate = [:]
        let allTodos = loadAllTodosUseCase.execute()
        for todo in allTodos {
            todosByDate[todo.date, default: []].append(todo)
        }
    }

    func todos(for date: Date) -> [TodoItem] {
        let key = date.toDateString()  // ✅ Date → "yyyy-MM-dd"
        return todosByDate[key] ?? []
    }

    func addTodo() {
        guard let date = selectedDate, !todoText.isEmpty else { return }
        let newTodo = TodoItem(
            text: todoText,
            isRepeating: isRepeating,
            date: date.toDateString(),
            colorName: selectedColorName
        )
        addTodoUseCase.execute(todo: newTodo)
        loadAllTodos()
    }

    func deleteTodo(_ todo: TodoItem) {
        deleteTodoUseCase.execute(todo: todo)
        loadAllTodos()
    }

    func updateTodo(original: TodoItem, updatedText: String, updatedColor: String) {
        let updatedTodo = TodoItem(
            id: original.id,
            text: updatedText,
            isRepeating: original.isRepeating,
            date: original.date,
            colorName: updatedColor
        )
        updateTodoUseCase.execute(original: original, updated: updatedTodo)
        loadAllTodos()
    }
}
