//
//  CalendarDay.swift
//  Nower
//
//  Created by 신종원 on 3/9/25.
//

import Foundation

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: String
    var todos: [TodoItem]
}

struct TodoItem: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let isRepeating: Bool
    let date: String
    let colorName: String
}
