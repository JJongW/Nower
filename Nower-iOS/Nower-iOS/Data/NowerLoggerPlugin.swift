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
        print("📤 [\(target.method.rawValue)] \(target.baseURL)\(target.path)")

        if let request = request.request,
           let headers = request.allHTTPHeaderFields {
            print("🧾 Headers: \(headers)")
        }

        if case let .requestParameters(parameters, _) = target.task {
            print("📦 Parameters: \(parameters)")
        }
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            print("✅ Response Status: \(response.statusCode)")
            if let json = try? JSONSerialization.jsonObject(with: response.data, options: .mutableContainers) {
                //print("🧪 Response JSON:\n\(json)")
            } else {
                print("🧪 Raw Data: \(String(data: response.data, encoding: .utf8) ?? "")")
            }
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
}
