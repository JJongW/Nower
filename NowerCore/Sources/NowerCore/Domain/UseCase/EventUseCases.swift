//
//  EventUseCases.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

// MARK: - Add Event

/// 일정 추가 UseCase
public protocol AddEventUseCase: Sendable {
    func execute(event: Event) -> Result<Event, NowerError>
}

/// 일정 추가 UseCase 기본 구현
public final class DefaultAddEventUseCase: AddEventUseCase, @unchecked Sendable {
    private let repository: EventRepository

    public init(repository: EventRepository) {
        self.repository = repository
    }

    public func execute(event: Event) -> Result<Event, NowerError> {
        // 유효성 검사
        guard !event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.validationFailed(reason: "일정 제목이 비어있습니다"))
        }

        guard event.endDateTime >= event.startDateTime else {
            return .failure(.validationFailed(reason: "종료 시간이 시작 시간보다 빠릅니다"))
        }

        return repository.save(event)
    }
}

// MARK: - Delete Event

/// 일정 삭제 UseCase
public protocol DeleteEventUseCase: Sendable {
    func execute(event: Event) -> Result<Void, NowerError>
}

/// 일정 삭제 UseCase 기본 구현
public final class DefaultDeleteEventUseCase: DeleteEventUseCase, @unchecked Sendable {
    private let repository: EventRepository

    public init(repository: EventRepository) {
        self.repository = repository
    }

    public func execute(event: Event) -> Result<Void, NowerError> {
        repository.delete(event)
    }
}

// MARK: - Update Event

/// 일정 수정 UseCase
public protocol UpdateEventUseCase: Sendable {
    func execute(original: Event, updated: Event) -> Result<Event, NowerError>
}

/// 일정 수정 UseCase 기본 구현
public final class DefaultUpdateEventUseCase: UpdateEventUseCase, @unchecked Sendable {
    private let repository: EventRepository

    public init(repository: EventRepository) {
        self.repository = repository
    }

    public func execute(original: Event, updated: Event) -> Result<Event, NowerError> {
        // 유효성 검사
        guard !updated.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.validationFailed(reason: "일정 제목이 비어있습니다"))
        }

        guard updated.endDateTime >= updated.startDateTime else {
            return .failure(.validationFailed(reason: "종료 시간이 시작 시간보다 빠릅니다"))
        }

        return repository.update(original: original, updated: updated)
    }
}

// MARK: - Fetch Events

/// 일정 조회 UseCase
public protocol FetchEventsUseCase: Sendable {
    func execute(for date: Date) -> Result<[Event], NowerError>
    func execute(for dateRange: DateInterval) -> Result<[Event], NowerError>
    func executeAll() -> Result<[Event], NowerError>
}

/// 일정 조회 UseCase 기본 구현
public final class DefaultFetchEventsUseCase: FetchEventsUseCase, @unchecked Sendable {
    private let repository: EventRepository

    public init(repository: EventRepository) {
        self.repository = repository
    }

    public func execute(for date: Date) -> Result<[Event], NowerError> {
        repository.fetch(on: date)
    }

    public func execute(for dateRange: DateInterval) -> Result<[Event], NowerError> {
        repository.fetch(for: dateRange)
    }

    public func executeAll() -> Result<[Event], NowerError> {
        repository.fetchAll()
    }
}

// MARK: - Move Event

/// 일정 이동 UseCase
public protocol MoveEventUseCase: Sendable {
    func execute(event: Event, to newDate: Date) -> Result<Event, NowerError>
}

/// 일정 이동 UseCase 기본 구현
public final class DefaultMoveEventUseCase: MoveEventUseCase, @unchecked Sendable {
    private let repository: EventRepository

    public init(repository: EventRepository) {
        self.repository = repository
    }

    public func execute(event: Event, to newDate: Date) -> Result<Event, NowerError> {
        // 기간별 일정은 이동 불가
        guard !event.isMultiDay else {
            return .failure(.validationFailed(reason: "기간별 일정은 이동할 수 없습니다"))
        }

        let calendar = Calendar.current

        // 새 날짜로 시작/종료 시간 계산
        let newStart: Date
        let newEnd: Date

        if event.isAllDay {
            newStart = calendar.startOfDay(for: newDate)
            var endComponents = DateComponents()
            endComponents.day = 1
            endComponents.second = -1
            newEnd = calendar.date(byAdding: endComponents, to: newStart) ?? newStart
        } else {
            // 시간은 유지하고 날짜만 변경
            let startComponents = calendar.dateComponents([.hour, .minute, .second], from: event.startDateTime)
            let endComponents = calendar.dateComponents([.hour, .minute, .second], from: event.endDateTime)

            let newStartDay = calendar.startOfDay(for: newDate)
            newStart = calendar.date(byAdding: startComponents, to: newStartDay) ?? newDate
            newEnd = calendar.date(byAdding: endComponents, to: newStartDay) ?? newDate
        }

        let movedEvent = event.updated(startDateTime: newStart, endDateTime: newEnd)
        return repository.update(original: event, updated: movedEvent)
    }
}

// MARK: - Delete Recurring Events

/// 반복 일정 전체 삭제 UseCase
public protocol DeleteRecurringEventsUseCase: Sendable {
    func execute(event: Event) -> Result<Int, NowerError>
}

/// 반복 일정 전체 삭제 UseCase 기본 구현
public final class DefaultDeleteRecurringEventsUseCase: DeleteRecurringEventsUseCase, @unchecked Sendable {
    private let repository: EventRepository

    public init(repository: EventRepository) {
        self.repository = repository
    }

    public func execute(event: Event) -> Result<Int, NowerError> {
        guard event.isRecurring else {
            // 반복 일정이 아니면 단일 삭제
            switch repository.delete(event) {
            case .success:
                return .success(1)
            case .failure(let error):
                return .failure(error)
            }
        }

        return repository.deleteAllRecurrences(of: event)
    }
}
