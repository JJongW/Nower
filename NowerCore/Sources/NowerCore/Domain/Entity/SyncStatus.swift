//
//  SyncStatus.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 동기화 상태
public enum SyncStatus: String, Codable, Sendable {
    /// 동기화 완료됨
    case synced

    /// 동기화 대기 중 (로컬 변경사항 있음)
    case pending

    /// 충돌 발생 (수동 해결 필요)
    case conflicted

    /// 동기화 실패
    case failed

    /// 동기화가 필요한지 여부
    public var needsSync: Bool {
        switch self {
        case .synced: return false
        case .pending, .conflicted, .failed: return true
        }
    }

    /// 표시용 문자열
    public var displayString: String {
        switch self {
        case .synced: return "동기화 완료"
        case .pending: return "동기화 대기"
        case .conflicted: return "충돌 발생"
        case .failed: return "동기화 실패"
        }
    }
}
