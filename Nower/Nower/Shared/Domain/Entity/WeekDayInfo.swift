//
//  WeekDayInfo.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 주의 각 날짜 정보
/// iOS 버전과 동일한 구조를 사용하여 일관성을 유지합니다.
struct WeekDayInfo {
    let day: Int? // nil이면 빈 날짜
    let dateString: String // yyyy-MM-dd 형식, 빈 날짜면 ""
    let todos: [TodoItem]
    let isToday: Bool
    let isSelected: Bool
    let holidayName: String?
    let isSunday: Bool
    let isSaturday: Bool
}
