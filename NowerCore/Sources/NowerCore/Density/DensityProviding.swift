//
//  DensityProviding.swift
//  NowerCore
//
//  하루 밀도 데이터 공급 계약.
//  플랫폼 어댑터(iOS: EventKit+HealthKit+MapKit, macOS: EventKit+MapKit)가
//  이 프로토콜을 구현해 DensityInput을 만들어 준다.
//  패키지는 계약만 정의하고, 프레임워크 의존은 앱 타겟에 둔다.
//

import Foundation

/// 특정 날짜의 밀도 입력을 비동기로 공급
public protocol DensityProviding: Sendable {
    /// 주어진 날짜의 일정·수면·이동을 모아 DensityInput으로 반환.
    /// 권한 없거나 데이터 없는 신호(sleep/travel)는 비워서 반환 → 엔진이 graceful degrade.
    func makeInput(for day: Date) async throws -> DensityInput
}

public extension DensityProviding {
    /// 입력 공급 + 엔진 채점을 한 번에. 어댑터 구현 후 호출부 단순화.
    func report(for day: Date) async throws -> DensityReport {
        let input = try await makeInput(for: day)
        return DensityEngine.score(input)
    }
}
