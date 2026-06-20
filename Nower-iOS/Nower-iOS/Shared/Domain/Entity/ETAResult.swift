//
//  ETAResult.swift
//  Nower-Shared
//
//  Created by AI Assistant on 6/17/26.
//  Copyright © 2026 Nower. All rights reserved.
//

import Foundation

/// 출발지→목적지 소요시간 추정 결과.
/// 자동차·대중교통을 둘 다 담으며, 한쪽이 불가하면 nil입니다.
struct ETAResult {
    /// 자동차 소요시간(분).
    let drivingMinutes: Int?
    /// 대중교통 소요시간(분).
    let transitMinutes: Int?

    var hasAny: Bool { drivingMinutes != nil || transitMinutes != nil }

    /// 알림 발송 시각 계산에 쓰는 보수적(가장 긴) 소요시간.
    /// 어떤 수단을 택하든 늦지 않도록 더 오래 걸리는 쪽을 기준으로 합니다.
    var conservativeMinutes: Int? {
        let candidates = [drivingMinutes, transitMinutes].compactMap { $0 }
        return candidates.max()
    }

    /// 알림 본문에 쓰는 소요시간 문구. 예: "차로 35분, 대중교통 48분"
    func travelPhrase() -> String {
        var parts: [String] = []
        if let d = drivingMinutes { parts.append("차로 \(d)분") }
        if let t = transitMinutes { parts.append("대중교통 \(t)분") }
        return parts.joined(separator: ", ")
    }
}
