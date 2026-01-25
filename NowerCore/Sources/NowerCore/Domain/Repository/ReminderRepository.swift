//
//  ReminderRepository.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 예약된 알림 정보
public struct ScheduledReminder: Identifiable, Sendable {
    public let id: String
    public let eventId: UUID
    public let eventTitle: String
    public let triggerDate: Date

    public init(id: String, eventId: UUID, eventTitle: String, triggerDate: Date) {
        self.id = id
        self.eventId = eventId
        self.eventTitle = eventTitle
        self.triggerDate = triggerDate
    }
}

/// 알림 저장소 프로토콜
/// 시스템 알림의 예약 및 관리를 추상화합니다.
public protocol ReminderRepository: Sendable {
    /// 알림 예약
    /// - Parameters:
    ///   - event: 일정
    ///   - reminder: 알림 설정
    /// - Returns: 성공 또는 에러
    func schedule(for event: Event, reminder: Reminder) async -> Result<Void, NowerError>

    /// 특정 알림 취소
    /// - Parameter notificationId: 알림 식별자
    func cancel(notificationId: String)

    /// 일정의 모든 알림 취소
    /// - Parameter event: 일정
    func cancelAll(for event: Event)

    /// 모든 알림 취소
    func cancelAll()

    /// 예약된 알림 목록 조회
    /// - Returns: 예약된 알림 배열
    func getPendingReminders() async -> [ScheduledReminder]

    /// 알림 권한 요청
    /// - Returns: 권한 허용 여부
    func requestPermission() async -> Bool

    /// 현재 알림 권한 상태 확인
    /// - Returns: 권한 허용 여부
    func hasPermission() async -> Bool

    /// 모든 알림 재예약 (앱 시작 시 호출)
    /// - Parameter events: 재예약할 일정 목록
    func rescheduleAll(for events: [Event]) async -> Result<Void, NowerError>
}
