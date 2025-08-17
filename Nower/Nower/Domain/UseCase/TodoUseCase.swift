//
//  TodoUseCase.swift
//  Nower (macOS)
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// Todo 추가를 담당하는 UseCase
protocol AddTodoUseCase {
    /// Todo를 추가합니다.
    /// - Parameter todo: 추가할 Todo
    func execute(todo: TodoItem)
}

/// Todo 삭제를 담당하는 UseCase
protocol DeleteTodoUseCase {
    /// Todo를 삭제합니다.
    /// - Parameter todo: 삭제할 Todo
    func execute(todo: TodoItem)
}

/// Todo 업데이트를 담당하는 UseCase
protocol UpdateTodoUseCase {
    /// Todo를 업데이트합니다.
    /// - Parameters:
    ///   - original: 원본 Todo
    ///   - updated: 업데이트된 Todo
    func execute(original: TodoItem, updated: TodoItem)
}

/// 특정 날짜의 Todo 조회를 담당하는 UseCase
protocol GetTodosByDateUseCase {
    /// 특정 날짜의 Todo를 조회합니다.
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 Todo 목록
    func execute(for date: Date) -> [TodoItem]
}

/// 모든 Todo 조회를 담당하는 UseCase
protocol LoadAllTodosUseCase {
    /// 모든 Todo를 조회합니다.
    /// - Returns: 모든 Todo 목록
    func execute() -> [TodoItem]
}

/// Todo 이동을 담당하는 UseCase
protocol MoveTodoUseCase {
    /// Todo를 다른 날짜로 이동합니다.
    /// - Parameters:
    ///   - todo: 이동할 Todo
    ///   - newDate: 새로운 날짜
    func execute(todo: TodoItem, to newDate: Date)
}
