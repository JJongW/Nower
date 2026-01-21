//
//  HolidayService.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/21/25.
//

import Foundation
import Moya
import Alamofire

// MARK: - 커스텀 URL 인코딩
/// 공공데이터포털 API의 파라미터 순서를 보장하는 커스텀 인코딩
/// 순서: solYear → solMonth → ServiceKey → _type
struct ServiceKeyLastEncoding: ParameterEncoding {
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        
        guard let url = urlRequest.url,
              var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let parameters = parameters else {
            return urlRequest
        }
        
        // 정확한 순서를 보장하기 위해 순서대로 추가
        // 공공데이터포털 API 요구사항: solYear → solMonth → ServiceKey
        var queryItems: [URLQueryItem] = []
        
        // 1. solYear (필수)
        if let solYear = parameters["solYear"] {
            queryItems.append(URLQueryItem(name: "solYear", value: "\(solYear)"))
        }
        
        // 2. solMonth (필수)
        if let solMonth = parameters["solMonth"] {
            queryItems.append(URLQueryItem(name: "solMonth", value: "\(solMonth)"))
        }
        
        // 3. ServiceKey (필수, 마지막에 위치)
        if let serviceKey = parameters["ServiceKey"] {
            queryItems.append(URLQueryItem(name: "ServiceKey", value: "\(serviceKey)"))
        }
        
        // 4. _type (선택적, JSON 응답을 위해)
        if let type = parameters["_type"] {
            queryItems.append(URLQueryItem(name: "_type", value: "\(type)"))
        }
        
        urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        urlRequest.url = urlComponents.url
        
        return urlRequest
    }
}

// MARK: - API 정의
enum HolidayService {
    case getHolidays(year: Int, month: Int)
}

extension HolidayService: TargetType {

    var baseURL: URL {
        // baseURL에는 기본 도메인과 경로만 포함 (쿼리 파라미터 제외)
        return URL(string: "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService")!
    }

    var path: String {
        switch self {
        case .getHolidays:
            return "/getRestDeInfo"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case .getHolidays(let year, let month):
            // API 키를 Info.plist에서 가져오기
            // 공공데이터포털 API는 ServiceKey를 URL 인코딩된 형태로 전달해야 함
            guard let serviceKey = Bundle.main.infoDictionary?["KASI_API_KEY"] as? String,
                  serviceKey != "$(KASI_API_KEY)",
                  let encodedKey = serviceKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                print("⚠️ KASI_API_KEY가 Info.plist에 설정되지 않았거나 올바르지 않습니다.")
                // 키가 없어도 API 호출은 진행 (401 에러가 발생할 것)
                let params: [String: Any] = [
                    "solYear": year,
                    "solMonth": String(format: "%02d", month),
                    "_type": "json",
                    "ServiceKey": ""
                ]
                return .requestParameters(parameters: params, encoding: ServiceKeyLastEncoding())
            }
            
            // ServiceKey를 마지막 파라미터로 배치하기 위해 순서를 보장하는 커스텀 인코딩 사용
            // 공공데이터포털 API 예제에서 ServiceKey가 마지막에 위치하도록 함
            let params: [String: Any] = [
                "solYear": year,
                "solMonth": String(format: "%02d", month),
                "_type": "json",
                "ServiceKey": encodedKey
            ]
            
            // ServiceKey를 마지막에 배치하는 커스텀 인코딩 사용
            return .requestParameters(parameters: params, encoding: ServiceKeyLastEncoding())
        }
    }

    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }

    var sampleData: Data {
        return Data()
    }
}
