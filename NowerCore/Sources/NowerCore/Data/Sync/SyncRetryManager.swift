//
//  SyncRetryManager.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 동기화 재시도 관리자 (지수 백오프 + 지터)
public final class SyncRetryManager {

    // MARK: - Constants

    private static let baseDelay: TimeInterval = 2.0
    private static let maxDelay: TimeInterval = 60.0
    private static let maxRetries: Int = 5
    private static let jitterRange: TimeInterval = 1.0

    // MARK: - Properties

    private var retryCount: Int = 0
    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue

    public var currentRetryCount: Int { retryCount }
    public var hasExhaustedRetries: Bool { retryCount >= Self.maxRetries }

    // MARK: - Initialization

    public init(queue: DispatchQueue = .global(qos: .utility)) {
        self.queue = queue
    }

    deinit {
        cancel()
    }

    // MARK: - Public Methods

    /// 지수 백오프 + 지터를 적용한 재시도를 스케줄링합니다.
    /// - Parameter action: 재시도 시 실행할 클로저
    /// - Returns: 재시도가 스케줄링되면 true, 최대 횟수 초과 시 false
    @discardableResult
    public func scheduleRetry(action: @escaping () -> Void) -> Bool {
        guard !hasExhaustedRetries else { return false }

        cancel()

        let delay = computeDelay()
        retryCount += 1

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + delay)
        timer.setEventHandler { [weak self] in
            self?.timer = nil
            action()
        }
        timer.resume()
        self.timer = timer

        return true
    }

    /// 재시도 카운터를 초기화합니다. 동기화 성공 시 호출합니다.
    public func reset() {
        cancel()
        retryCount = 0
    }

    /// 진행 중인 타이머를 취소합니다.
    public func cancel() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - Private

    private func computeDelay() -> TimeInterval {
        // 2s, 4s, 8s, 16s, 32s (capped at 60s)
        let exponential = Self.baseDelay * pow(2.0, Double(retryCount))
        let capped = min(exponential, Self.maxDelay)
        let jitter = TimeInterval.random(in: 0...Self.jitterRange)
        return capped + jitter
    }
}
