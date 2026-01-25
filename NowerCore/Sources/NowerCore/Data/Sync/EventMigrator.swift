//
//  EventMigrator.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 레거시 TodoItem에서 Event로의 마이그레이션 유틸리티
public struct EventMigrator {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// 단일 LegacyTodoItem을 Event로 변환
    /// - Parameter todoItem: 변환할 레거시 아이템
    /// - Returns: 변환된 Event
    public static func migrate(from todoItem: LegacyTodoItem) -> Event {
        let startDate: Date
        let endDate: Date

        if todoItem.isPeriodEvent,
           let startStr = todoItem.startDate,
           let endStr = todoItem.endDate,
           let start = dateFormatter.date(from: startStr),
           let end = dateFormatter.date(from: endStr) {
            // 기간별 일정
            startDate = Calendar.current.startOfDay(for: start)
            var endComponents = DateComponents()
            endComponents.day = 1
            endComponents.second = -1
            endDate = Calendar.current.date(byAdding: endComponents, to: Calendar.current.startOfDay(for: end)) ?? end
        } else if let date = dateFormatter.date(from: todoItem.date) {
            // 단일 날짜 일정
            startDate = Calendar.current.startOfDay(for: date)
            var endComponents = DateComponents()
            endComponents.day = 1
            endComponents.second = -1
            endDate = Calendar.current.date(byAdding: endComponents, to: startDate) ?? startDate
        } else {
            // 날짜 파싱 실패 시 현재 날짜 사용
            startDate = Calendar.current.startOfDay(for: Date())
            endDate = startDate
        }

        // 반복 규칙 변환
        let recurrenceRule: RecurrenceRule? = todoItem.isRepeating ? .daily : nil

        return Event(
            id: todoItem.id,
            title: todoItem.text,
            colorTheme: ColorTheme.from(legacyColorName: todoItem.colorName),
            startDateTime: startDate,
            endDateTime: endDate,
            isAllDay: true, // 레거시 데이터는 모두 하루 종일
            timeZone: .current,
            recurrenceRule: recurrenceRule,
            reminders: [],
            createdAt: Date(),
            modifiedAt: Date(),
            syncStatus: .synced,
            location: nil,
            notes: nil,
            url: nil
        )
    }

    /// 여러 LegacyTodoItem을 Event 배열로 변환
    /// - Parameter todoItems: 변환할 레거시 아이템 배열
    /// - Returns: 변환된 Event 배열
    public static func migrate(from todoItems: [LegacyTodoItem]) -> [Event] {
        todoItems.map(migrate(from:))
    }
}

/// 데이터 마이그레이션 관리자
public final class MigrationManager {
    private var storage: StorageProvider
    private let currentVersion: Int = 2 // v1 = LegacyTodoItem, v2 = Event

    public init(storage: StorageProvider) {
        self.storage = storage
    }

    /// 마이그레이션 필요 여부 확인
    public var needsMigration: Bool {
        storage.schemaVersion < currentVersion
    }

    /// 마이그레이션 실행
    /// - Returns: 성공 또는 에러
    public func migrateIfNeeded() -> Result<Void, NowerError> {
        let storedVersion = storage.schemaVersion

        guard storedVersion < currentVersion else {
            return .success(())
        }

        // v1 → v2 마이그레이션
        if storedVersion < 2 {
            let result = migrateV1ToV2()
            if case .failure(let error) = result {
                return .failure(error)
            }
        }

        // 버전 업데이트
        storage.schemaVersion = currentVersion
        storage.synchronize()

        return .success(())
    }

    /// v1 (LegacyTodoItem) → v2 (Event) 마이그레이션
    private func migrateV1ToV2() -> Result<Void, NowerError> {
        // 레거시 데이터 로드
        let legacyResult: Result<[LegacyTodoItem]?, NowerError> = storage.load(forKey: StorageKeys.legacyTodos)

        guard case .success(let legacyItems) = legacyResult else {
            if case .failure(let error) = legacyResult {
                return .failure(error)
            }
            return .success(()) // 데이터 없음
        }

        guard let items = legacyItems, !items.isEmpty else {
            return .success(()) // 데이터 없음
        }

        // Event로 변환
        let events = EventMigrator.migrate(from: items)

        // 새 형식으로 저장
        let saveResult = storage.save(events, forKey: StorageKeys.events)
        if case .failure = saveResult {
            return .failure(.migrationFailed(fromVersion: 1, toVersion: 2))
        }

        // 백업 저장
        _ = storage.save(items, forKey: StorageKeys.legacyBackup)

        return .success(())
    }

    /// 마이그레이션 롤백 (백업에서 복원)
    public func rollback() -> Result<Void, NowerError> {
        let backupResult: Result<[LegacyTodoItem]?, NowerError> = storage.load(forKey: StorageKeys.legacyBackup)

        guard case .success(let backup) = backupResult, let items = backup else {
            return .failure(.unknown(message: "백업 데이터를 찾을 수 없습니다"))
        }

        // 레거시 형식으로 복원
        let saveResult = storage.save(items, forKey: StorageKeys.legacyTodos)
        if case .failure(let error) = saveResult {
            return .failure(error)
        }

        // 버전 롤백
        storage.schemaVersion = 1

        // 새 형식 데이터 삭제
        storage.remove(forKey: StorageKeys.events)
        storage.synchronize()

        return .success(())
    }
}
