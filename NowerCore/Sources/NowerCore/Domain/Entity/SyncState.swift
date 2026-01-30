//
//  SyncState.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 동기화 상태를 나타내는 모델
public struct SyncState: Equatable, Sendable {

    /// 동기화 단계
    public enum Phase: Equatable, Sendable {
        case idle
        case syncing
        case synced
        case failed(NowerError)
        case conflicted
    }

    public let phase: Phase
    public let lastSyncDate: Date?
    public let pendingChangeCount: Int
    public let conflicts: [SyncConflict]

    public init(
        phase: Phase,
        lastSyncDate: Date? = nil,
        pendingChangeCount: Int = 0,
        conflicts: [SyncConflict] = []
    ) {
        self.phase = phase
        self.lastSyncDate = lastSyncDate
        self.pendingChangeCount = pendingChangeCount
        self.conflicts = conflicts
    }

    /// 초기 상태
    public static let initial = SyncState(phase: .idle)
}
