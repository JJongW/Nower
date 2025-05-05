//
//  HolidayService.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/21/25.
//

import Foundation
import Moya

// MARK: - API 정의
enum HolidayService {
    case getHolidays(year: Int, month: Int)
}

struct NonEncodedServiceKey: CustomStringConvertible {
    let value: String
    var description: String { value }
}

extension HolidayService: TargetType {

    var baseURL: URL {
       let rawKey = Bundle.main.infoDictionary?["KASI_API_KEY"] as? String ?? "NO_KEY_FOUND"
       let urlString = "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo?ServiceKey=\(rawKey)"
       return URL(string: urlString)!
    }

    var path: String { "" }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        switch self {
        case .getHolidays(let year, let month):
            let params: [String: Any] = [
                "solYear": year,
                "solMonth": String(format: "%02d", month),
                "_type": "json"
            ]
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }

    var sampleData: Data {
        return Data()
    }
}
