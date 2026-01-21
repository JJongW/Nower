//
//  NowerLoggerPlugin.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/21/25.
//

import Moya
import Foundation

final class NowerLoggerPlugin: PluginType {
    func willSend(_ request: RequestType, target: TargetType) {
        // 요청 정보는 HolidayAPIClient에서 상세히 로깅하므로 여기서는 최소한만 출력
        // (중복 로그 방지)
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        // 응답 정보는 HolidayAPIClient에서 상세히 로깅하므로 여기서는 최소한만 출력
        // (중복 로그 방지)
    }
}
