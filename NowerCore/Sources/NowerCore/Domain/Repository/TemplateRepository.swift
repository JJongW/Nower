//
//  TemplateRepository.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 이벤트 템플릿 저장소 프로토콜
public protocol TemplateRepository: Sendable {
    /// 템플릿 저장 (중복 ID면 업데이트)
    func save(_ template: EventTemplate) -> Result<EventTemplate, NowerError>

    /// 템플릿 삭제
    func delete(_ template: EventTemplate) -> Result<Void, NowerError>

    /// 전체 템플릿 조회
    func fetchAll() -> Result<[EventTemplate], NowerError>

    /// 접두사로 필터링된 템플릿 조회 (in-memory 필터, 대소문자 무시)
    func fetch(matchingPrefix prefix: String) -> Result<[EventTemplate], NowerError>
}
