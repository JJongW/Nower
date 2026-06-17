//
//  AppUpdateChecker.swift
//  Nower-iOS
//
//  App Store 최신 버전을 iTunes Lookup API 로 조회해 업데이트 필요 여부를 판정한다.
//  - 소프트(권장): 설치 버전 < 스토어 최신 버전
//  - 하드(강제): 설치 버전 < AppUpdateConfig.minimumRequiredVersion
//  네트워크 실패 시에는 막지 않는다(fail-open) — 오프라인 사용자를 가두지 않기 위함.
//

import Foundation

/// 강제 업데이트 정책 상수.
/// 깨지는 변경이나 보안 이슈가 있는 릴리스를 낼 때 `minimumRequiredVersion` 을 올린다.
/// (iTunes Lookup 은 '최소 강제 버전'을 원격으로 줄 수 없어 로컬 상수로 관리한다.)
enum AppUpdateConfig {
    /// 이 버전 미만이면 진입을 막는다. nil 이면 강제 차단 없음(권장 안내만).
    static let minimumRequiredVersion: String? = nil
}

enum AppUpdateStatus: Equatable {
    /// 최신이거나, 판정 불가(오프라인 등) — 진행 허용
    case upToDate
    /// 권장 업데이트 — 닫기 가능한 안내
    case optional(storeVersion: String, appStoreURL: URL)
    /// 강제 업데이트 — 진입 차단
    case required(storeVersion: String, appStoreURL: URL)
}

struct AppUpdateChecker {

    private let bundleId: String
    private let installedVersion: String
    private let minimumRequiredVersion: String?
    private let session: URLSession

    init(
        bundleId: String? = Bundle.main.bundleIdentifier,
        installedVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        minimumRequiredVersion: String? = AppUpdateConfig.minimumRequiredVersion,
        session: URLSession = .shared
    ) {
        self.bundleId = bundleId ?? ""
        self.installedVersion = installedVersion ?? "0"
        self.minimumRequiredVersion = minimumRequiredVersion
        self.session = session
    }

    /// 업데이트 상태를 판정한다. 실패하면 `.upToDate`(fail-open).
    func check() async -> AppUpdateStatus {
        guard !bundleId.isEmpty,
              let lookup = await fetchStoreInfo() else {
            return .upToDate
        }

        // 강제: 설치 < 최소 요구 버전
        if let minVersion = minimumRequiredVersion,
           installedVersion.isVersion(lessThan: minVersion) {
            return .required(storeVersion: lookup.version, appStoreURL: lookup.url)
        }

        // 권장: 설치 < 스토어 최신
        if installedVersion.isVersion(lessThan: lookup.version) {
            return .optional(storeVersion: lookup.version, appStoreURL: lookup.url)
        }

        return .upToDate
    }

    // MARK: - iTunes Lookup

    private struct StoreInfo {
        let version: String
        let url: URL
    }

    private func fetchStoreInfo() async -> StoreInfo? {
        let region = Locale.current.region?.identifier.lowercased() ?? "kr"
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleId),
            URLQueryItem(name: "country", value: region)
        ]
        guard let url = components?.url else { return nil }

        do {
            let (data, _) = try await session.data(from: url)
            let result = try JSONDecoder().decode(LookupResponse.self, from: data)
            guard let app = result.results.first else { return nil }

            let storeURL = URL(string: "itms-apps://itunes.apple.com/app/id\(app.trackId)")
                ?? URL(string: app.trackViewUrl)
            guard let storeURL else { return nil }
            return StoreInfo(version: app.version, url: storeURL)
        } catch {
            return nil
        }
    }

    private struct LookupResponse: Decodable {
        let results: [Result]
        struct Result: Decodable {
            let version: String
            let trackId: Int
            let trackViewUrl: String
        }
    }
}

private extension String {
    /// 점 구분 시맨틱 버전 비교. "1.2" < "1.2.1", "1.10" > "1.9".
    func isVersion(lessThan other: String) -> Bool {
        let lhs = split(separator: ".").map { Int($0) ?? 0 }
        let rhs = other.split(separator: ".").map { Int($0) ?? 0 }
        let count = Swift.max(lhs.count, rhs.count)
        for i in 0..<count {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < rhs.count ? rhs[i] : 0
            if l != r { return l < r }
        }
        return false
    }
}
