//
//  TodoUseCase.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation

protocol AddTodoUseCase { func execute(todo: TodoItem) }
protocol DeleteTodoUseCase { func execute(todo: TodoItem) }
protocol UpdateTodoUseCase { func execute(original: TodoItem, updated: TodoItem) }
protocol GetTodosByDateUseCase { func execute(for date: Date) -> [TodoItem] }
protocol LoadAllTodosUseCase { func execute() -> [TodoItem] }
