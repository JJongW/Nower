//
//  LegacyTodoItem.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 레거시 TodoItem 모델 (마이그레이션 전용)
/// 기존 데이터와의 호환성을 위해 유지됩니다.
/// 새로운 코드에서는 Event 모델을 사용하세요.
public struct LegacyTodoItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public let text: String
    public let isRepeating: Bool
    public let date: String // yyyy-MM-dd 형식
    public let colorName: String

    // 기간별 일정을 위한 필드
    public let startDate: String?
    public let endDate: String?

    public init(
        id: UUID = UUID(),
        text: String,
        isRepeating: Bool,
        date: String,
        colorName: String,
        startDate: String? = nil,
        endDate: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isRepeating = isRepeating
        self.date = date
        self.colorName = colorName
        self.startDate = startDate
        self.endDate = endDate
    }

    // MARK: - Hashable

    public static func == (lhs: LegacyTodoItem, rhs: LegacyTodoItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Computed Properties

public extension LegacyTodoItem {
    /// 기간별 일정인지 확인
    var isPeriodEvent: Bool {
        startDate != nil && endDate != nil
    }

    /// 단일 날짜 일정인지 확인
    var isSingleDayEvent: Bool {
        !isPeriodEvent
    }

    /// date 문자열을 Date 객체로 변환
    var dateObject: Date? {
        Self.dateFormatter.date(from: date)
    }

    /// startDate 문자열을 Date 객체로 변환
    var startDateObject: Date? {
        guard let startDate = startDate else { return dateObject }
        return Self.dateFormatter.date(from: startDate)
    }

    /// endDate 문자열을 Date 객체로 변환
    var endDateObject: Date? {
        guard let endDate = endDate else { return dateObject }
        return Self.dateFormatter.date(from: endDate)
    }

    /// 일정 기간 (일)
    var durationInDays: Int {
        guard isPeriodEvent,
              let start = startDateObject,
              let end = endDateObject else { return 1 }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return (components.day ?? 0) + 1
    }

    /// 특정 날짜가 일정에 포함되는지 확인
    func includesDate(_ date: Date) -> Bool {
        let dateString = Self.dateFormatter.string(from: date)

        if isPeriodEvent {
            guard let start = startDate, let end = endDate else { return false }
            return dateString >= start && dateString <= end
        } else {
            return self.date == dateString
        }
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
