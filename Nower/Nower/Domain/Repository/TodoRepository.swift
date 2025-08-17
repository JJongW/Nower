//
//  TodoRepository.swift
//  Nower (macOS)
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// Todo 데이터 관리를 위한 Repository Protocol
/// 데이터 소스에 대한 추상화를 제공하여 비즈니스 로직과 데이터 레이어를 분리합니다.
protocol TodoRepository {
    /// 모든 Todo를 조회합니다.
    /// - Returns: 모든 Todo 목록
    func getAllTodos() -> [TodoItem]
    
    /// 특정 날짜의 Todo를 조회합니다.
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 Todo 목록
    func getTodos(for date: Date) -> [TodoItem]
    
    /// Todo를 추가합니다.
    /// - Parameter todo: 추가할 Todo
    func addTodo(_ todo: TodoItem)
    
    /// Todo를 삭제합니다.
    /// - Parameter todo: 삭제할 Todo
    func deleteTodo(_ todo: TodoItem)
    
    /// Todo를 업데이트합니다.
    /// - Parameters:
    ///   - original: 원본 Todo
    ///   - updated: 업데이트된 Todo
    func updateTodo(original: TodoItem, with updated: TodoItem)
    
    /// 수동으로 동기화를 수행합니다.
    func forceSynchronize()
}
