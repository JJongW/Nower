//
//  HolidayAPIClient.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/21/25.
//
import Moya
import Foundation

let provider = MoyaProvider<HolidayService>(plugins: [NowerLoggerPlugin()])

func fetchHolidaysMoya(year: Int, month: Int, completion: @escaping ([Holiday]) -> Void) {
    provider.request(.getHolidays(year: year, month: month)) { result in
        switch result {
        case .success(let response):
            print("📎 최종 URL: \(response.request?.url?.absoluteString ?? "없음")")
            print("📦 응답 상태 코드: \(response.statusCode)")
            print("📦 응답 바디: \(String(data: response.data, encoding: .utf8) ?? "")")
            do {
                let decoded = try JSONDecoder().decode(HolidayResponse.self, from: response.data)
                let holidays = decoded.response.body.holidays
                print("✅ 디코딩된 공휴일:")
                for h in holidays {
                    print("📅 \(h.dateName) - \(h.locdate)")
                }
                completion(holidays)
            } catch {
                print("❌ JSON 디코딩 실패:", error)
            }
        case .failure(let error):
            print("❌ 네트워크 실패:", error)
        }
    }
}
