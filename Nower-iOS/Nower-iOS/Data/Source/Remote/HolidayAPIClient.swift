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
                let urlString = response.request?.url?.absoluteString ?? "없음"
                let responseBody = String(data: response.data, encoding: .utf8) ?? ""
                
                // HTTP 상태 코드 확인 (200이 아니면 에러)
                guard (200...299).contains(response.statusCode) else {
                    // 401 에러인 경우 상세한 디버깅 정보 출력
                    if response.statusCode == 401 {
                        self.log401Error(urlString: urlString, responseBody: responseBody)
                    } else {
                        print("❌ [공휴일 API] HTTP 에러 \(response.statusCode): \(responseBody)")
                    }
                    
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
                    print("❌ [공휴일 API] 응답 데이터가 비어있습니다.")
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
                    print("❌ [공휴일 API] 응답이 JSON 형식이 아닙니다.")
                    print("   응답 내용: \(responseBody)")
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
                    print("✅ [공휴일 API] 성공 - 공휴일 \(holidays.count)개 조회됨")
                    if holidays.count > 0 {
                        holidays.forEach { print("   📅 \($0.dateName) - \($0.locdate)") }
                    }
                    completion(.success(holidays))
                } catch {
                    print("❌ [공휴일 API] JSON 디코딩 실패")
                    print("   에러: \(error.localizedDescription)")
                    print("   응답 바디: \(responseBody.prefix(200))")
                    completion(.failure(error))
                }
            case .failure(let error):
                print("❌ [공휴일 API] 네트워크 요청 실패")
                print("   에러: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    /// 401 Unauthorized 에러 발생 시 상세한 디버깅 정보를 출력
    /// - Parameters:
    ///   - urlString: 요청한 URL
    ///   - responseBody: 응답 바디
    private func log401Error(urlString: String, responseBody: String) {
        print("\n" + String(repeating: "=", count: 60))
        print("🔒 [공휴일 API] 401 Unauthorized 에러 발생")
        print(String(repeating: "=", count: 60))
        
        // 1. 요청 URL 확인
        print("\n📎 요청 URL:")
        print("   \(urlString)")
        
        // 2. URL에서 ServiceKey 확인
        if let url = URL(string: urlString),
           let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            print("\n📋 URL 파라미터:")
            for item in queryItems {
                if item.name == "ServiceKey" {
                    let keyValue = item.value ?? ""
                    let isKeySet = !keyValue.isEmpty && keyValue != "$(KASI_API_KEY)"
                    print("   \(item.name): \(isKeySet ? "✅ 설정됨 (\(keyValue.prefix(20))...)" : "❌ 설정 안됨 또는 잘못됨")")
                } else {
                    print("   \(item.name): \(item.value ?? "없음")")
                }
            }
        }
        
        // 3. Info.plist에서 API 키 확인
        let serviceKey = Bundle.main.infoDictionary?["KASI_API_KEY"] as? String ?? "없음"
        let isKeyConfigured = serviceKey != "없음" && serviceKey != "$(KASI_API_KEY)" && !serviceKey.isEmpty
        print("\n🔑 API 키 설정 상태:")
        print("   KASI_API_KEY: \(isKeyConfigured ? "✅ 설정됨" : "❌ 설정 안됨 또는 잘못됨")")
        if !isKeyConfigured {
            print("   ⚠️ Info.plist 또는 Build Settings에서 KASI_API_KEY를 확인하세요")
        }
        
        // 4. 응답 내용
        print("\n📦 서버 응답:")
        print("   \(responseBody)")
        
        // 5. 가능한 원인
        print("\n💡 가능한 원인:")
        if !isKeyConfigured {
            print("   1. API 키가 설정되지 않았습니다.")
            print("      → Info.plist의 KASI_API_KEY 값 확인")
            print("      → Xcode Build Settings의 User-Defined 변수 확인")
        }
        if urlString.contains("ServiceKey=") && !urlString.contains("ServiceKey=%") {
            print("   2. ServiceKey가 URL 인코딩되지 않았습니다.")
        }
        print("   3. API 키가 만료되었거나 잘못된 키입니다.")
        print("   4. 공공데이터포털에서 API 키 권한이 설정되지 않았습니다.")
        
        print(String(repeating: "=", count: 60) + "\n")
    }
}
