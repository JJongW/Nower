//
//  SyncConflict.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 동기화 충돌 정보
public struct SyncConflict: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let localTitle: String
    public let localColorName: String
    public let localDate: String
    public let localModifiedAt: Date

    public let remoteTitle: String
    public let remoteColorName: String
    public let remoteDate: String
    public let remoteModifiedAt: Date

    public let detectedAt: Date

    public init(
        id: UUID,
        localTitle: String,
        localColorName: String,
        localDate: String,
        localModifiedAt: Date,
        remoteTitle: String,
        remoteColorName: String,
        remoteDate: String,
        remoteModifiedAt: Date,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.localTitle = localTitle
        self.localColorName = localColorName
        self.localDate = localDate
        self.localModifiedAt = localModifiedAt
        self.remoteTitle = remoteTitle
        self.remoteColorName = remoteColorName
        self.remoteDate = remoteDate
        self.remoteModifiedAt = remoteModifiedAt
        self.detectedAt = detectedAt
    }
}

/// 충돌 해결 방식
public enum ConflictResolution: Sendable {
    case keepLocal
    case keepRemote
    case keepBoth
}
