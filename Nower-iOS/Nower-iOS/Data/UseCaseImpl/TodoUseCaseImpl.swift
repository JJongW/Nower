//
//  TodoUseCaseImpl.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//


import Foundation

final class DefaultAddTodoUseCase: AddTodoUseCase {
    private let repository: TodoRepository
    init(repository: TodoRepository) { self.repository = repository }
    func execute(todo: TodoItem) { repository.addTodo(todo) }
}

final class DefaultDeleteTodoUseCase: DeleteTodoUseCase {
    private let repository: TodoRepository
    init(repository: TodoRepository) { self.repository = repository }
    func execute(todo: TodoItem) { repository.deleteTodo(todo) }
}

final class DefaultUpdateTodoUseCase: UpdateTodoUseCase {
    private let repository: TodoRepository
    init(repository: TodoRepository) { self.repository = repository }
    func execute(original: TodoItem, updated: TodoItem) {
        repository.updateTodo(original, with: updated)
    }
}

final class DefaultGetTodosByDateUseCase: GetTodosByDateUseCase {
    private let repository: TodoRepository
    init(repository: TodoRepository) { self.repository = repository }
    func execute(for date: Date) -> [TodoItem] {
        return repository.fetchTodos(on: date)
    }
}

final class DefaultLoadAllTodosUseCase: LoadAllTodosUseCase {
    private let repository: TodoRepository
    init(repository: TodoRepository) { self.repository = repository }
    func execute() -> [TodoItem] {
        return repository.allTodos()
    }
}
