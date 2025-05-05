//
//  TodoRepositoryProtocol.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation

protocol TodoRepository {
    func fetchTodos(on date: Date) -> [TodoItem]
    func addTodo(_ todo: TodoItem)
    func deleteTodo(_ todo: TodoItem)
    func updateTodo(_ original: TodoItem, with updated: TodoItem)
    func allTodos() -> [TodoItem]
}
