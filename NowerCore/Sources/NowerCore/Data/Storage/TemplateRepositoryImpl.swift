//
//  TemplateRepositoryImpl.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// TemplateRepository 기본 구현
public final class TemplateRepositoryImpl: TemplateRepository, @unchecked Sendable {
    private let storage: StorageProvider
    private let queue: DispatchQueue
    private var cachedTemplates: [EventTemplate]?

    public init(storage: StorageProvider) {
        self.storage = storage
        self.queue = DispatchQueue(label: "com.nower.templateRepository", qos: .userInitiated)
    }

    // MARK: - Private Helpers

    private func loadTemplates() -> [EventTemplate] {
        if let cached = cachedTemplates {
            return cached
        }

        let result: Result<[EventTemplate]?, NowerError> = storage.load(forKey: StorageKeys.eventTemplates)
        if case .success(let templates) = result {
            let loaded = templates ?? []
            cachedTemplates = loaded
            return loaded
        }
        return []
    }

    private func saveTemplates(_ templates: [EventTemplate]) -> Result<Void, NowerError> {
        cachedTemplates = templates
        return storage.save(templates, forKey: StorageKeys.eventTemplates)
    }

    // MARK: - TemplateRepository

    public func save(_ template: EventTemplate) -> Result<EventTemplate, NowerError> {
        return queue.sync {
            var templates = loadTemplates()

            if let index = templates.firstIndex(where: { $0.id == template.id }) {
                templates[index] = template
            } else {
                templates.append(template)
            }

            switch saveTemplates(templates) {
            case .success:
                storage.synchronize()
                return .success(template)
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    public func delete(_ template: EventTemplate) -> Result<Void, NowerError> {
        return queue.sync {
            var templates = loadTemplates()
            templates.removeAll { $0.id == template.id }

            switch saveTemplates(templates) {
            case .success:
                storage.synchronize()
                return .success(())
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    public func fetchAll() -> Result<[EventTemplate], NowerError> {
        queue.sync {
            let templates = loadTemplates()
            let sorted = templates.sorted { $0.createdAt < $1.createdAt }
            return .success(sorted)
        }
    }

    public func fetch(matchingPrefix prefix: String) -> Result<[EventTemplate], NowerError> {
        queue.sync {
            let templates = loadTemplates()
            let trimmed = prefix.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else {
                return .success([])
            }
            let lower = trimmed.lowercased()
            let filtered = templates.filter {
                $0.name.lowercased().hasPrefix(lower) || $0.title.lowercased().hasPrefix(lower)
            }
            let sorted = filtered.sorted { $0.createdAt < $1.createdAt }
            return .success(sorted)
        }
    }
}
