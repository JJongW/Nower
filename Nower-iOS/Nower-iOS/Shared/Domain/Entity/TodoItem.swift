//
//  TodoItem.swift
//  Nower-Shared
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 공통 Todo 아이템 데이터 모델
/// MacOS와 iOS에서 동일하게 사용되는 핵심 엔티티입니다.
struct TodoItem: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isRepeating: Bool
    let date: String // yyyy-MM-dd 형식
    let colorName: String
    
    /// 새로운 TodoItem을 생성합니다.
    /// - Parameters:
    ///   - text: Todo 내용
    ///   - isRepeating: 반복 여부
    ///   - date: 날짜 (yyyy-MM-dd 형식)
    ///   - colorName: 색상 이름
    init(text: String, isRepeating: Bool, date: String, colorName: String) {
        self.text = text
        self.isRepeating = isRepeating
        self.date = date
        self.colorName = colorName
    }
    
    /// Date 객체로부터 TodoItem을 생성하는 편의 생성자
    /// - Parameters:
    ///   - text: Todo 내용
    ///   - isRepeating: 반복 여부
    ///   - date: Date 객체
    ///   - colorName: 색상 이름
    init(text: String, isRepeating: Bool, date: Date, colorName: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        self.text = text
        self.isRepeating = isRepeating
        self.date = formatter.string(from: date)
        self.colorName = colorName
    }
}

// MARK: - Hashable
extension TodoItem: Hashable {
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 편의 메서드
extension TodoItem {
    /// 날짜 문자열을 Date 객체로 변환합니다.
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    /// 같은 날짜인지 확인합니다.
    /// - Parameter date: 비교할 Date 객체
    /// - Returns: 같은 날짜인지 여부
    func isOnSameDate(as date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return self.date == formatter.string(from: date)
    }
}
