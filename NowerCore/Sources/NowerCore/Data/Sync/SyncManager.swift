//
//  SyncManager.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 동기화 변경 알림
public extension Notification.Name {
    static let eventsDidUpdate = Notification.Name("NowerCore.eventsDidUpdate")
    static let syncDidStart = Notification.Name("NowerCore.syncDidStart")
    static let syncDidComplete = Notification.Name("NowerCore.syncDidComplete")
    static let syncDidFail = Notification.Name("NowerCore.syncDidFail")
}

/// 동기화 관리자 프로토콜
public protocol SyncManager: Sendable {
    /// 동기화 강제 실행
    func forceSynchronize()

    /// 외부 변경사항 감지 시작
    func startListening()

    /// 외부 변경사항 감지 중지
    func stopListening()

    /// 마지막 동기화 시간
    var lastSyncDate: Date? { get }

    /// 동기화 사용 가능 여부
    var isAvailable: Bool { get }
}

/// iCloud 동기화 관리자
public final class iCloudSyncManager: SyncManager, @unchecked Sendable {
    private let storage: StorageProvider
    private let eventRepository: EventRepository
    private var isListening: Bool = false

    #if canImport(Foundation)
    private var observer: NSObjectProtocol?
    #endif

    public init(storage: StorageProvider, eventRepository: EventRepository) {
        self.storage = storage
        self.eventRepository = eventRepository
    }

    deinit {
        stopListening()
    }

    public var isAvailable: Bool {
        storage.isAvailable
    }

    public var lastSyncDate: Date? {
        let result: Result<Date?, NowerError> = storage.load(forKey: StorageKeys.lastSyncDate)
        if case .success(let date) = result {
            return date
        }
        return nil
    }

    public func forceSynchronize() {
        storage.synchronize()

        // 마지막 동기화 시간 업데이트
        _ = storage.save(Date(), forKey: StorageKeys.lastSyncDate)

        // 동기화 완료 알림
        NotificationCenter.default.post(name: .syncDidComplete, object: nil)
    }

    public func startListening() {
        guard !isListening else { return }
        isListening = true

        #if canImport(Foundation)
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] notification in
            self?.handleExternalChange(notification)
        }
        #endif
    }

    public func stopListening() {
        guard isListening else { return }
        isListening = false

        #if canImport(Foundation)
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        #endif
    }

    private func handleExternalChange(_ notification: Notification) {
        // 변경 사유 확인
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            // 서버에서 변경사항 도착
            NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)

        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            // 할당량 초과
            NotificationCenter.default.post(
                name: .syncDidFail,
                object: nil,
                userInfo: ["error": NowerError.syncFailed(message: "iCloud 할당량 초과")]
            )

        case NSUbiquitousKeyValueStoreAccountChange:
            // 계정 변경
            NotificationCenter.default.post(name: .eventsDidUpdate, object: nil)

        default:
            break
        }
    }
}

/// 로컬 전용 동기화 관리자 (오프라인용)
public final class LocalSyncManager: SyncManager, @unchecked Sendable {
    public init() {}

    public var isAvailable: Bool { true }
    public var lastSyncDate: Date? { Date() }

    public func forceSynchronize() {
        // 로컬 저장소는 동기화 불필요
    }

    public func startListening() {
        // 로컬 저장소는 외부 변경 없음
    }

    public func stopListening() {
        // 로컬 저장소는 외부 변경 없음
    }
}
