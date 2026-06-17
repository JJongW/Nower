//
//  SavedPlace.swift
//  Nower-Shared
//
//  Created by AI Assistant on 6/16/26.
//  Copyright © 2026 Nower. All rights reserved.
//

import Foundation

// MARK: - 저장 장소 종류

/// 저장 장소의 종류.
/// `home`/`work`는 이름이 고정된 슬롯, `custom`은 사용자가 추가한 자유 장소입니다.
enum PlaceKind: String, Codable {
    case home   // 집 (고정 슬롯)
    case work   // 회사 (고정 슬롯)
    case custom // 자유 장소

    /// 고정 슬롯의 표시 이름. custom은 사용자 지정 이름을 쓰므로 nil.
    var fixedName: String? {
        switch self {
        case .home: return "집"
        case .work: return "회사"
        case .custom: return nil
        }
    }

    /// 신규 사용자에게 기본 제공되는 별칭(매칭어) 세트.
    var defaultAliases: [String] {
        switch self {
        case .home: return ["집", "본가", "집에", "우리집"]
        case .work: return ["회사", "사무실", "출근", "오피스", "직장"]
        case .custom: return []
        }
    }
}

// MARK: - 저장 장소

/// 출발 알림이 출발지/목적지로 사용하는 저장된 장소.
/// 일정 텍스트를 별칭과 매칭해 좌표를 자동으로 잡습니다.
struct SavedPlace: Identifiable, Codable, Hashable {
    var id = UUID()
    let kind: PlaceKind

    /// 표시 이름. 고정 슬롯이면 "집"/"회사"로 박히고, custom이면 사용자 지정.
    var name: String

    /// 좌표 (비어 있으면 알림 비활성).
    var latitude: Double?
    var longitude: Double?

    /// 사람이 읽는 주소(선택).
    var address: String?

    /// 일정 텍스트 매칭에 쓰는 별칭 목록.
    var aliases: [String]

    /// 출발 알림 대상 여부. 고정 슬롯은 기본 true, 자유 장소는 V1에서 false(저장만).
    var nudgeEnabled: Bool

    init(
        id: UUID = UUID(),
        kind: PlaceKind,
        name: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        aliases: [String]? = nil,
        nudgeEnabled: Bool? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.aliases = aliases ?? kind.defaultAliases
        self.nudgeEnabled = nudgeEnabled ?? (kind != .custom)
    }

    /// 좌표가 모두 있어 ETA 계산이 가능한지.
    var hasCoordinate: Bool {
        latitude != nil && longitude != nil
    }

    /// 빈 고정 슬롯(집/회사) 시드를 생성합니다.
    static func emptyFixed(_ kind: PlaceKind) -> SavedPlace {
        SavedPlace(kind: kind, name: kind.fixedName ?? "")
    }

    // MARK: - 매칭

    /// 일정 텍스트가 이 장소의 별칭 중 하나를 포함하는지 검사합니다.
    /// 대소문자·공백을 정규화해 부분 포함으로 매칭합니다.
    func matches(eventText: String) -> Bool {
        let haystack = SavedPlace.normalize(eventText)
        guard !haystack.isEmpty else { return false }
        return aliases.contains { alias in
            let needle = SavedPlace.normalize(alias)
            return !needle.isEmpty && haystack.contains(needle)
        }
    }

    /// 매칭 비교를 위한 문자열 정규화(소문자 + 공백 제거).
    static func normalize(_ s: String) -> String {
        s.lowercased().replacingOccurrences(of: " ", with: "")
    }
}
