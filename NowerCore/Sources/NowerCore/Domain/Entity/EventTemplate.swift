//
//  EventTemplate.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 이벤트 템플릿 — 자주 쓰는 일정 양식을 저장하여 자동완성에 활용
public struct EventTemplate: Identifiable, Codable, Hashable, Sendable {
    /// 고유 식별자
    public var id: UUID

    /// 자동완성 목록에 표시되는 레이블 (예: "치과")
    public let name: String

    /// 이벤트 제목 필드에 채워지는 값 (예: "치과 정기검진")
    public let title: String

    /// 색상 이름 (기존 colorName 포맷, 예: "skyblue-4")
    public let colorName: String

    /// 반복 규칙 (nil = 반복 없음)
    public let recurrenceRule: RecurrenceRule?

    /// 생성 일시
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        title: String,
        colorName: String = "skyblue-4",
        recurrenceRule: RecurrenceRule? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.colorName = colorName
        self.recurrenceRule = recurrenceRule
        self.createdAt = createdAt
    }

    // MARK: - Hashable

    public static func == (lhs: EventTemplate, rhs: EventTemplate) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
