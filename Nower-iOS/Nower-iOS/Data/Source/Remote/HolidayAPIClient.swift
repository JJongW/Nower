//
//  HolidayAPIClient.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/21/25.
//

import Moya
import Foundation

final class HolidayAPIClient {
    private let provider = MoyaProvider<HolidayService>(plugins: [NowerLoggerPlugin()])

    func fetchHolidays(year: Int, month: Int, completion: @escaping (Result<[Holiday], Error>) -> Void) {
        provider.request(.getHolidays(year: year, month: month)) { result in
            switch result {
            case .success(let response):
                print("📎 최종 URL: \(response.request?.url?.absoluteString ?? "없음")")
                print("📦 응답 상태 코드: \(response.statusCode)")
                print("📦 응답 바디: \(String(data: response.data, encoding: .utf8) ?? "")")
                do {
                    let decoded = try JSONDecoder().decode(HolidayResponse.self, from: response.data)
                    let holidays = decoded.response.body.items!.item
                    print("✅ 디코딩된 공휴일:")
                    holidays.forEach { print("📅 \($0.dateName) - \($0.locdate)") }
                    completion(.success(holidays))
                } catch {
                    print("❌ JSON 디코딩 실패:", error)
                    completion(.failure(error))
                }
            case .failure(let error):
                print("❌ 네트워크 실패:", error)
                completion(.failure(error))
            }
        }
    }
}
