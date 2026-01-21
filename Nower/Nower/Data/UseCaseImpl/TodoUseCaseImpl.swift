//
//  TodoUseCaseImpl.swift
//  Nower (macOS)
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

// MARK: - AddTodoUseCase Implementation
final class DefaultAddTodoUseCase: AddTodoUseCase {
    private let repository: TodoRepository
    
    init(repository: TodoRepository) {
        self.repository = repository
    }
    
    func execute(todo: TodoItem) {
        repository.addTodo(todo)
    }
}

// MARK: - DeleteTodoUseCase Implementation
final class DefaultDeleteTodoUseCase: DeleteTodoUseCase {
    private let repository: TodoRepository
    
    init(repository: TodoRepository) {
        self.repository = repository
    }
    
    func execute(todo: TodoItem) {
        repository.deleteTodo(todo)
    }
}

// MARK: - UpdateTodoUseCase Implementation
final class DefaultUpdateTodoUseCase: UpdateTodoUseCase {
    private let repository: TodoRepository
    
    init(repository: TodoRepository) {
        self.repository = repository
    }
    
    func execute(original: TodoItem, updated: TodoItem) {
        repository.updateTodo(original: original, with: updated)
    }
}

// MARK: - GetTodosByDateUseCase Implementation
final class DefaultGetTodosByDateUseCase: GetTodosByDateUseCase {
    private let repository: TodoRepository
    
    init(repository: TodoRepository) {
        self.repository = repository
    }
    
    func execute(for date: Date) -> [TodoItem] {
        return repository.getTodos(for: date)
    }
}

// MARK: - LoadAllTodosUseCase Implementation
final class DefaultLoadAllTodosUseCase: LoadAllTodosUseCase {
    private let repository: TodoRepository
    
    init(repository: TodoRepository) {
        self.repository = repository
    }
    
    func execute() -> [TodoItem] {
        return repository.getAllTodos()
    }
}

// MARK: - MoveTodoUseCase Implementation
final class DefaultMoveTodoUseCase: MoveTodoUseCase {
    private let repository: TodoRepository
    
    init(repository: TodoRepository) {
        self.repository = repository
    }
    
    func execute(todo: TodoItem, to newDate: Date) {
        // 기존 Todo 삭제
        repository.deleteTodo(todo)
        
        // 새로운 날짜로 Todo 생성
        let movedTodo = TodoItem(
            text: todo.text,
            isRepeating: todo.isRepeating,
            date: newDate,
            colorName: todo.colorName
        )
        
        // 새로운 Todo 추가
        repository.addTodo(movedTodo)
    }
}
