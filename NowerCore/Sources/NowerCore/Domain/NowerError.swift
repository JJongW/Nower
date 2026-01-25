//
//  NowerError.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// Nower 앱에서 발생할 수 있는 에러 타입
public enum NowerError: LocalizedError, Equatable {
    /// 저장소를 사용할 수 없음
    case storageUnavailable

    /// 동기화 실패
    case syncFailed(message: String)

    /// 유효성 검사 실패
    case validationFailed(reason: String)

    /// 마이그레이션 실패
    case migrationFailed(fromVersion: Int, toVersion: Int)

    /// 알림 권한 거부됨
    case notificationPermissionDenied

    /// 일정을 찾을 수 없음
    case eventNotFound(id: UUID)

    /// 인코딩 실패
    case encodingFailed

    /// 디코딩 실패
    case decodingFailed

    /// 네트워크 오류
    case networkError(message: String)

    /// 알 수 없는 오류
    case unknown(message: String)

    public var errorDescription: String? {
        switch self {
        case .storageUnavailable:
            return "저장소를 사용할 수 없습니다"
        case .syncFailed(let message):
            return "동기화 실패: \(message)"
        case .validationFailed(let reason):
            return "유효성 검사 실패: \(reason)"
        case .migrationFailed(let from, let to):
            return "데이터 마이그레이션 실패 (v\(from) → v\(to))"
        case .notificationPermissionDenied:
            return "알림 권한이 거부되었습니다"
        case .eventNotFound(let id):
            return "일정을 찾을 수 없습니다: \(id)"
        case .encodingFailed:
            return "데이터 인코딩에 실패했습니다"
        case .decodingFailed:
            return "데이터 디코딩에 실패했습니다"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .unknown(let message):
            return "알 수 없는 오류: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .storageUnavailable:
            return "iCloud 설정을 확인하고 다시 시도해주세요"
        case .syncFailed:
            return "네트워크 연결을 확인하고 다시 시도해주세요"
        case .validationFailed:
            return "입력값을 확인해주세요"
        case .migrationFailed:
            return "앱을 재설치하거나 지원팀에 문의해주세요"
        case .notificationPermissionDenied:
            return "설정에서 알림 권한을 허용해주세요"
        case .eventNotFound:
            return "일정이 삭제되었거나 동기화되지 않았을 수 있습니다"
        case .encodingFailed, .decodingFailed:
            return "앱을 재시작해주세요"
        case .networkError:
            return "네트워크 연결을 확인하고 다시 시도해주세요"
        case .unknown:
            return "문제가 지속되면 지원팀에 문의해주세요"
        }
    }
}

// MARK: - Result Extension

public extension Result where Failure == NowerError {
    /// 성공 여부
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    /// 실패 여부
    var isFailure: Bool {
        !isSuccess
    }

    /// 성공 값 (없으면 nil)
    var successValue: Success? {
        if case .success(let value) = self { return value }
        return nil
    }

    /// 에러 (없으면 nil)
    var error: NowerError? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
