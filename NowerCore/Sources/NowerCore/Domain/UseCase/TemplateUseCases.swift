//
//  TemplateUseCases.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

// MARK: - Save Template

/// 템플릿 저장 UseCase
public protocol SaveTemplateUseCase: Sendable {
    func execute(_ template: EventTemplate) -> Result<EventTemplate, NowerError>
}

/// 템플릿 저장 UseCase 기본 구현
public final class DefaultSaveTemplateUseCase: SaveTemplateUseCase, @unchecked Sendable {
    private let repository: TemplateRepository

    public init(repository: TemplateRepository) {
        self.repository = repository
    }

    public func execute(_ template: EventTemplate) -> Result<EventTemplate, NowerError> {
        guard !template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.validationFailed(reason: "템플릿 이름이 비어있습니다"))
        }
        guard !template.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.validationFailed(reason: "템플릿 제목이 비어있습니다"))
        }
        return repository.save(template)
    }
}

// MARK: - Delete Template

/// 템플릿 삭제 UseCase
public protocol DeleteTemplateUseCase: Sendable {
    func execute(_ template: EventTemplate) -> Result<Void, NowerError>
}

/// 템플릿 삭제 UseCase 기본 구현
public final class DefaultDeleteTemplateUseCase: DeleteTemplateUseCase, @unchecked Sendable {
    private let repository: TemplateRepository

    public init(repository: TemplateRepository) {
        self.repository = repository
    }

    public func execute(_ template: EventTemplate) -> Result<Void, NowerError> {
        repository.delete(template)
    }
}

// MARK: - Fetch Templates

/// 템플릿 조회 UseCase
public protocol FetchTemplatesUseCase: Sendable {
    func executeAll() -> Result<[EventTemplate], NowerError>
    func execute(matchingPrefix prefix: String) -> Result<[EventTemplate], NowerError>
}

/// 템플릿 조회 UseCase 기본 구현
public final class DefaultFetchTemplatesUseCase: FetchTemplatesUseCase, @unchecked Sendable {
    private let repository: TemplateRepository

    public init(repository: TemplateRepository) {
        self.repository = repository
    }

    public func executeAll() -> Result<[EventTemplate], NowerError> {
        repository.fetchAll()
    }

    public func execute(matchingPrefix prefix: String) -> Result<[EventTemplate], NowerError> {
        repository.fetch(matchingPrefix: prefix)
    }
}
