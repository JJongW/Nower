//
//  DepartureSettings.swift
//  Nower-Shared
//
//  Created by AI Assistant on 6/16/26.
//  Copyright © 2026 Nower. All rights reserved.
//

import Foundation

/// 출발 알림 전역 설정.
/// 저장 장소 목록 + 알림 계산에 쓰는 기본값(준비 버퍼, 안전 여유, 출근 의존규칙)을 담습니다.
struct DepartureSettings: Codable {
    /// 저장 장소 목록. 항상 집·회사 고정 슬롯 2개를 포함하고, 뒤에 자유 장소가 붙습니다.
    var places: [SavedPlace]

    /// 준비 버퍼 기본값(분). 대화로 학습되기 전 초기값.
    var defaultBufferMinutes: Int

    /// 안전 여유(분). 늦지 않도록 더하는 마진.
    var safetyMarginMinutes: Int

    /// 출근 의존규칙: 출근/회사 일정의 기본 출발지를 집으로 잡을지.
    var commuteOriginIsHome: Bool

    // MARK: - 기본값

    static let defaultBuffer = 30
    static let defaultSafetyMargin = 5

    /// 집·회사 빈 고정 슬롯 + 기본값으로 시작하는 초기 설정.
    static var initial: DepartureSettings {
        DepartureSettings(
            places: [.emptyFixed(.home), .emptyFixed(.work)],
            defaultBufferMinutes: defaultBuffer,
            safetyMarginMinutes: defaultSafetyMargin,
            commuteOriginIsHome: true
        )
    }

    // MARK: - 조회 헬퍼

    /// 고정 슬롯(집/회사)을 반환합니다.
    func fixedPlace(_ kind: PlaceKind) -> SavedPlace? {
        places.first { $0.kind == kind }
    }

    /// 알림 대상이면서 좌표가 있는 장소만 추립니다.
    var nudgeReadyPlaces: [SavedPlace] {
        places.filter { $0.nudgeEnabled && $0.hasCoordinate }
    }

    /// 일정 텍스트에 매칭되는 알림 대상 장소를 찾습니다.
    /// 고정 슬롯(집/회사)을 자유 장소보다 우선합니다.
    func matchPlace(for eventText: String) -> SavedPlace? {
        let ready = nudgeReadyPlaces
        if let fixed = ready.first(where: { $0.kind != .custom && $0.matches(eventText: eventText) }) {
            return fixed
        }
        return ready.first { $0.matches(eventText: eventText) }
    }
}
