//
//  TodoItem.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/12/25.
//

import Foundation

struct TodoItem: Identifiable, Hashable, Codable {
    var id = UUID()
    let text: String
    let isRepeating: Bool
    let date: String
    let colorName: String
}
