//
//  Todo.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isRepeating: Bool
    let date: String
    let colorName: String
}

extension TodoItem: Hashable {
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
