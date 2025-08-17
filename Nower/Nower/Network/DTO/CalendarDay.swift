//
//  CalendarDay.swift
//  Nower
//
//  Created by 신종원 on 3/9/25.
//  DEPRECATED: Use Shared/Domain/Entity instead
//

import Foundation

/// ⚠️ DEPRECATED: 이 파일은 더 이상 사용하지 않습니다.
/// Shared/Domain/Entity/CalendarDay.swift를 사용해주세요.
@available(*, deprecated, message: "Use Shared/Domain/Entity/CalendarDay.swift instead")
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: String
    var todos: [TodoItem]
}

/// ⚠️ DEPRECATED: 이 파일은 더 이상 사용하지 않습니다.
/// Shared/Domain/Entity/TodoItem.swift를 사용해주세요.
@available(*, deprecated, message: "Use Shared/Domain/Entity/TodoItem.swift instead")
struct TodoItem: Identifiable, Hashable, Codable {
    var id = UUID()
    let text: String
    let isRepeating: Bool
    let date: String
    let colorName: String
}
