//
//  CalendarDay.swift
//  Nower-Shared
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 달력의 하루를 나타내는 데이터 모델
/// MacOS와 iOS에서 동일하게 사용되는 달력 뷰 엔티티입니다.
struct CalendarDay: Identifiable, Codable {
    var id = UUID()
    let date: String // yyyy-MM-dd 형식, 빈 날짜인 경우 빈 문자열
    var todos: [TodoItem]
    
    /// 새로운 CalendarDay를 생성합니다.
    /// - Parameters:
    ///   - date: 날짜 문자열 (yyyy-MM-dd 형식)
    ///   - todos: 해당 날짜의 Todo 목록
    init(date: String, todos: [TodoItem] = []) {
        self.date = date
        self.todos = todos
    }
    
    /// Date 객체로부터 CalendarDay를 생성하는 편의 생성자
    /// - Parameters:
    ///   - date: Date 객체
    ///   - todos: 해당 날짜의 Todo 목록
    init(date: Date, todos: [TodoItem] = []) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        self.date = formatter.string(from: date)
        self.todos = todos
    }
}

// MARK: - 편의 메서드
extension CalendarDay {
    /// 빈 날짜인지 확인합니다 (달력 패딩용)
    var isEmpty: Bool {
        return date.isEmpty
    }
    
    /// 날짜 문자열을 Date 객체로 변환합니다.
    var dateObject: Date? {
        guard !isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    /// Todo가 있는지 확인합니다.
    var hasTodos: Bool {
        return !todos.isEmpty
    }
    
    /// 특정 색상의 Todo 개수를 반환합니다.
    /// - Parameter colorName: 색상 이름
    /// - Returns: 해당 색상의 Todo 개수
    func todoCount(for colorName: String) -> Int {
        return todos.filter { $0.colorName == colorName }.count
    }
    
    /// Todo를 추가합니다.
    /// - Parameter todo: 추가할 Todo
    mutating func addTodo(_ todo: TodoItem) {
        todos.append(todo)
    }
    
    /// Todo를 제거합니다.
    /// - Parameter todoId: 제거할 Todo의 ID
    mutating func removeTodo(with todoId: UUID) {
        todos.removeAll { $0.id == todoId }
    }
}
