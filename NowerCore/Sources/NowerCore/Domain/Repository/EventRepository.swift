//
//  EventRepository.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 일정 저장소 프로토콜
/// 일정 데이터의 CRUD 연산을 추상화합니다.
public protocol EventRepository: Sendable {
    /// 일정 저장
    /// - Parameter event: 저장할 일정
    /// - Returns: 저장된 일정 또는 에러
    func save(_ event: Event) -> Result<Event, NowerError>

    /// 일정 삭제
    /// - Parameter event: 삭제할 일정
    /// - Returns: 성공 또는 에러
    func delete(_ event: Event) -> Result<Void, NowerError>

    /// ID로 일정 조회
    /// - Parameter id: 일정 ID
    /// - Returns: 일정 또는 nil
    func fetch(id: UUID) -> Event?

    /// 날짜 범위로 일정 조회
    /// - Parameter dateRange: 조회할 날짜 범위
    /// - Returns: 일정 배열 또는 에러
    func fetch(for dateRange: DateInterval) -> Result<[Event], NowerError>

    /// 특정 날짜의 일정 조회
    /// - Parameter date: 조회할 날짜
    /// - Returns: 일정 배열 또는 에러
    func fetch(on date: Date) -> Result<[Event], NowerError>

    /// 모든 일정 조회
    /// - Returns: 전체 일정 배열 또는 에러
    func fetchAll() -> Result<[Event], NowerError>

    /// 일정 업데이트
    /// - Parameters:
    ///   - original: 원본 일정
    ///   - updated: 수정된 일정
    /// - Returns: 업데이트된 일정 또는 에러
    func update(original: Event, updated: Event) -> Result<Event, NowerError>

    /// 여러 일정 일괄 저장
    /// - Parameter events: 저장할 일정 배열
    /// - Returns: 성공 또는 에러
    func saveAll(_ events: [Event]) -> Result<Void, NowerError>

    /// 여러 일정 일괄 삭제
    /// - Parameter events: 삭제할 일정 배열
    /// - Returns: 성공 또는 에러
    func deleteAll(_ events: [Event]) -> Result<Void, NowerError>

    /// 반복 일정의 모든 인스턴스 삭제
    /// - Parameter event: 반복 일정
    /// - Returns: 삭제된 개수 또는 에러
    func deleteAllRecurrences(of event: Event) -> Result<Int, NowerError>
}

// MARK: - Default Implementations

public extension EventRepository {
    /// 특정 날짜의 일정 조회 (기본 구현)
    func fetch(on date: Date) -> Result<[Event], NowerError> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return .failure(.unknown(message: "날짜 계산 실패"))
        }
        let interval = DateInterval(start: start, end: end)
        return fetch(for: interval)
    }

    /// 이번 달 일정 조회
    func fetchCurrentMonth() -> Result<[Event], NowerError> {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            return .failure(.unknown(message: "월 범위 계산 실패"))
        }
        return fetch(for: monthInterval)
    }

    /// 오늘 일정 조회
    func fetchToday() -> Result<[Event], NowerError> {
        fetch(on: Date())
    }
}
