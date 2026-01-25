//
//  Location.swift
//  NowerCore
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 일정의 위치 정보
public struct Location: Codable, Hashable, Sendable {
    /// 위치 이름 (예: "스타벅스 강남점")
    public let name: String

    /// 상세 주소 (선택적)
    public let address: String?

    /// 위도 (선택적, 지도 표시용)
    public let latitude: Double?

    /// 경도 (선택적, 지도 표시용)
    public let longitude: Double?

    public init(
        name: String,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }

    /// 좌표가 유효한지 확인
    public var hasValidCoordinates: Bool {
        guard let lat = latitude, let lon = longitude else { return false }
        return (-90...90).contains(lat) && (-180...180).contains(lon)
    }

    /// 표시용 문자열
    public var displayString: String {
        if let address = address, !address.isEmpty {
            return "\(name) (\(address))"
        }
        return name
    }
}

// MARK: - Convenience Initializers

public extension Location {
    /// 이름만으로 위치 생성
    static func named(_ name: String) -> Location {
        Location(name: name)
    }

    /// 전체 정보로 위치 생성
    static func full(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double
    ) -> Location {
        Location(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude
        )
    }
}
