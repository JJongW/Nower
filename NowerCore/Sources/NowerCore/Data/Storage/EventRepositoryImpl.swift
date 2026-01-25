//
//  EventRepositoryImpl.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// EventRepository 기본 구현
public final class EventRepositoryImpl: EventRepository, @unchecked Sendable {
    private let storage: StorageProvider
    private let queue: DispatchQueue
    private var cachedEvents: [Event]?

    public init(storage: StorageProvider) {
        self.storage = storage
        self.queue = DispatchQueue(label: "com.nower.eventRepository", qos: .userInitiated)
    }

    // MARK: - Private Helpers

    private func loadEvents() -> [Event] {
        if let cached = cachedEvents {
            return cached
        }

        let result: Result<[Event]?, NowerError> = storage.load(forKey: StorageKeys.events)
        if case .success(let events) = result {
            let loaded = events ?? []
            cachedEvents = loaded
            return loaded
        }
        return []
    }

    private func saveEvents(_ events: [Event]) -> Result<Void, NowerError> {
        cachedEvents = events
        return storage.save(events, forKey: StorageKeys.events)
    }

    private func invalidateCache() {
        cachedEvents = nil
    }

    // MARK: - EventRepository

    public func save(_ event: Event) -> Result<Event, NowerError> {
        return queue.sync {
            var events = loadEvents()

            // 중복 확인
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = event.withSyncStatus(.pending)
            } else {
                events.append(event.withSyncStatus(.pending))
            }

            switch saveEvents(events) {
            case .success:
                storage.synchronize()
                return .success(event)
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    public func delete(_ event: Event) -> Result<Void, NowerError> {
        return queue.sync {
            var events = loadEvents()
            events.removeAll { $0.id == event.id }

            switch saveEvents(events) {
            case .success:
                storage.synchronize()
                return .success(())
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    public func fetch(id: UUID) -> Event? {
        queue.sync {
            loadEvents().first { $0.id == id }
        }
    }

    public func fetch(for dateRange: DateInterval) -> Result<[Event], NowerError> {
        queue.sync {
            let events = loadEvents()
            let filtered = events.filter { event in
                // 일정이 범위와 겹치는지 확인
                let eventInterval = DateInterval(start: event.startDateTime, end: event.endDateTime)
                return eventInterval.intersects(dateRange)
            }

            // 시작 시간순 정렬
            let sorted = filtered.sorted { $0.startDateTime < $1.startDateTime }
            return .success(sorted)
        }
    }

    public func fetch(on date: Date) -> Result<[Event], NowerError> {
        return queue.sync {
            let events = loadEvents()
            let filtered = events.filter { event in
                event.includesDate(date)
            }

            // 시작 시간순 정렬
            let sorted = filtered.sorted { $0.startDateTime < $1.startDateTime }
            return .success(sorted)
        }
    }

    public func fetchAll() -> Result<[Event], NowerError> {
        queue.sync {
            let events = loadEvents()
            let sorted = events.sorted { $0.startDateTime < $1.startDateTime }
            return .success(sorted)
        }
    }

    public func update(original: Event, updated: Event) -> Result<Event, NowerError> {
        return queue.sync {
            var events = loadEvents()

            guard let index = events.firstIndex(where: { $0.id == original.id }) else {
                return .failure(.eventNotFound(id: original.id))
            }

            // ID 유지, 동기화 상태 pending으로 변경
            var newEvent = updated
            newEvent.id = original.id
            newEvent.syncStatus = .pending
            events[index] = newEvent

            switch saveEvents(events) {
            case .success:
                storage.synchronize()
                return .success(newEvent)
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    public func saveAll(_ events: [Event]) -> Result<Void, NowerError> {
        queue.sync {
            var allEvents = loadEvents()

            for event in events {
                if let index = allEvents.firstIndex(where: { $0.id == event.id }) {
                    allEvents[index] = event.withSyncStatus(.pending)
                } else {
                    allEvents.append(event.withSyncStatus(.pending))
                }
            }

            switch saveEvents(allEvents) {
            case .success:
                storage.synchronize()
                return .success(())
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    public func deleteAll(_ events: [Event]) -> Result<Void, NowerError> {
        queue.sync {
            var allEvents = loadEvents()
            let idsToDelete = Set(events.map { $0.id })
            allEvents.removeAll { idsToDelete.contains($0.id) }

            switch saveEvents(allEvents) {
            case .success:
                storage.synchronize()
                return .success(())
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    public func deleteAllRecurrences(of event: Event) -> Result<Int, NowerError> {
        // 현재 구현에서는 반복 일정을 별도로 저장하지 않으므로
        // 단일 이벤트만 삭제
        switch delete(event) {
        case .success:
            return .success(1)
        case .failure(let error):
            return .failure(error)
        }
    }
}
