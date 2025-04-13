//
//  CalendarDay.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/12/25.
//

import Foundation

struct CalendarDay: Identifiable, Codable {
    var id = UUID()
    let date: String
    var todos: [TodoItem]
}
