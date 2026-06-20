//
//  DirectionsProvider.swift
//  Nower-iOS
//
//  Created by AI Assistant on 6/17/26.
//  Copyright © 2026 Nower. All rights reserved.
//

import Foundation

/// 출발지→목적지 소요시간(ETA)을 제공하는 추상화.
/// 기본 구현은 KakaoDirectionsProvider(실시간 교통 반영)이며,
/// 키가 없거나 네트워크가 실패하면 MockDirectionsProvider로 폴백합니다.
protocol DirectionsProvider {
    /// 두 좌표 사이 자동차·대중교통 소요시간을 추정합니다.
    func estimate(
        fromLat: Double, fromLng: Double,
        toLat: Double, toLng: Double
    ) async -> ETAResult
}

/// 더미 ETA를 반환하는 Mock 구현.
/// 두 좌표의 직선거리(Haversine)에 평균 속도를 적용해 대략적인 분을 만듭니다.
/// 실제 API 연동 전 파이프라인(알림 계산·스케줄·UI)을 끝까지 검증하는 용도입니다.
struct MockDirectionsProvider: DirectionsProvider {
    /// 자동차 평균 속도(km/h).
    private let drivingKmh: Double
    /// 대중교통 평균 속도(km/h).
    private let transitKmh: Double
    /// 최소 소요시간(분). 아주 가까워도 이 값 이상.
    private let minMinutes: Int

    init(drivingKmh: Double = 35, transitKmh: Double = 22, minMinutes: Int = 5) {
        self.drivingKmh = drivingKmh
        self.transitKmh = transitKmh
        self.minMinutes = minMinutes
    }

    func estimate(
        fromLat: Double, fromLng: Double,
        toLat: Double, toLng: Double
    ) async -> ETAResult {
        let km = Self.haversineKm(lat1: fromLat, lng1: fromLng, lat2: toLat, lng2: toLng)
        let driving = minutes(forKm: km, kmh: drivingKmh)
        let transit = minutes(forKm: km, kmh: transitKmh)
        return ETAResult(drivingMinutes: driving, transitMinutes: transit)
    }

    private func minutes(forKm km: Double, kmh: Double) -> Int {
        guard kmh > 0 else { return minMinutes }
        let mins = Int((km / kmh * 60).rounded())
        return max(minMinutes, mins)
    }

    /// 두 좌표 사이 직선거리(km).
    static func haversineKm(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let earthRadius = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLng = (lng2 - lng1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(dLng / 2) * sin(dLng / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}

// MARK: - Kakao Mobility

/// 카카오모빌리티 길찾기 API로 자동차 소요시간(실시간 교통 반영)을 받아오는 구현.
/// 대중교통 소요시간은 카카오 길찾기가 제공하지 않으므로, 응답으로 받은 실제
/// 도로 거리에 대중교통 평균 속도를 적용한 추정값으로 채웁니다.
///
/// 키가 없거나(빌드 설정 미주입) 네트워크/응답이 실패하면 `fallback`(기본 Mock)으로
/// 조용히 대체해 출발 알림 파이프라인이 끊기지 않게 합니다(fail-open).
struct KakaoDirectionsProvider: DirectionsProvider {
    private let apiKey: String?
    private let fallback: DirectionsProvider
    private let session: URLSession
    /// 대중교통 평균 속도(km/h) — 실제 도로 거리에 적용해 대략적인 분을 만듭니다.
    private let transitKmh: Double
    private let minMinutes: Int

    init(
        apiKey: String? = Bundle.main.infoDictionary?["KAKAO_REST_API_KEY"] as? String,
        fallback: DirectionsProvider = MockDirectionsProvider(),
        session: URLSession = .shared,
        transitKmh: Double = 22,
        minMinutes: Int = 5
    ) {
        self.apiKey = apiKey
        self.fallback = fallback
        self.session = session
        self.transitKmh = transitKmh
        self.minMinutes = minMinutes
    }

    /// 빌드 설정에서 주입되지 않았으면(placeholder/빈 값) nil.
    private var resolvedKey: String? {
        guard let raw = apiKey, !raw.isEmpty, raw != "$(KAKAO_REST_API_KEY)" else { return nil }
        return raw
    }

    func estimate(
        fromLat: Double, fromLng: Double,
        toLat: Double, toLng: Double
    ) async -> ETAResult {
        guard let key = resolvedKey,
              var components = URLComponents(string: "https://apis-navi.kakaomobility.com/v1/directions")
        else {
            return await fallback.estimate(fromLat: fromLat, fromLng: fromLng, toLat: toLat, toLng: toLng)
        }

        // 카카오 좌표 포맷: "경도,위도"(x,y)
        components.queryItems = [
            URLQueryItem(name: "origin", value: "\(fromLng),\(fromLat)"),
            URLQueryItem(name: "destination", value: "\(toLng),\(toLat)"),
            URLQueryItem(name: "priority", value: "RECOMMEND")
        ]
        guard let url = components.url else {
            return await fallback.estimate(fromLat: fromLat, fromLng: fromLng, toLat: toLat, toLng: toLng)
        }

        var request = URLRequest(url: url)
        request.setValue("KakaoAK \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return await fallback.estimate(fromLat: fromLat, fromLng: fromLng, toLat: toLat, toLng: toLng)
            }
            let decoded = try JSONDecoder().decode(KakaoDirectionsResponse.self, from: data)
            guard let route = decoded.routes.first, route.resultCode == 0, let summary = route.summary else {
                return await fallback.estimate(fromLat: fromLat, fromLng: fromLng, toLat: toLat, toLng: toLng)
            }
            let drivingMin = max(minMinutes, Int((Double(summary.duration) / 60).rounded()))
            let km = Double(summary.distance) / 1000
            let transitMin = transitKmh > 0
                ? max(minMinutes, Int((km / transitKmh * 60).rounded()))
                : nil
            return ETAResult(drivingMinutes: drivingMin, transitMinutes: transitMin)
        } catch {
            return await fallback.estimate(fromLat: fromLat, fromLng: fromLng, toLat: toLat, toLng: toLng)
        }
    }
}

/// 카카오 길찾기 응답에서 필요한 필드만 디코딩.
private struct KakaoDirectionsResponse: Decodable {
    let routes: [Route]

    struct Route: Decodable {
        let resultCode: Int
        let summary: Summary?

        enum CodingKeys: String, CodingKey {
            case resultCode = "result_code"
            case summary
        }
    }

    struct Summary: Decodable {
        let distance: Int // meters
        let duration: Int // seconds
    }
}
