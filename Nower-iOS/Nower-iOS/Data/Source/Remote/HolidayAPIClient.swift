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
                let responseBody = String(data: response.data, encoding: .utf8) ?? ""
                
                // HTTP 상태 코드 확인 (200이 아니면 에러)
                guard (200...299).contains(response.statusCode) else {
                    let error = NSError(
                        domain: "HolidayAPIClient",
                        code: response.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP 에러 \(response.statusCode): \(responseBody)"]
                    )
                    completion(.failure(error))
                    return
                }
                
                // 응답 데이터가 비어있는지 확인
                guard !response.data.isEmpty else {
                    let error = NSError(
                        domain: "HolidayAPIClient",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "응답 데이터가 비어있습니다."]
                    )
                    completion(.failure(error))
                    return
                }
                
                // JSON 형식인지 확인 (첫 문자가 '{' 또는 '['인지)
                let trimmedBody = responseBody.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedBody.hasPrefix("{") || trimmedBody.hasPrefix("[") else {
                    let error = NSError(
                        domain: "HolidayAPIClient",
                        code: -2,
                        userInfo: [
                            NSLocalizedDescriptionKey: "응답이 JSON 형식이 아닙니다.",
                            "responseBody": responseBody
                        ]
                    )
                    completion(.failure(error))
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(HolidayResponse.self, from: response.data)
                    let holidays = decoded.response.body.items?.item ?? []
                    completion(.success(holidays))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
