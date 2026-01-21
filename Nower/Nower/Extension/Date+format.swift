//
//  Date+format.swift
//  Nower
//
//  Created by 신종원 on 4/20/25.
//  Updated for iOS compatibility on 5/12/25.
//

import Foundation

extension Date {
    /// 날짜를 지정된 형식의 문자열로 변환합니다.
    /// - Parameter format: 날짜 형식 (기본값: "yyyy.MM.dd")
    /// - Returns: 포맷된 날짜 문자열
    func formatted(_ format: String = "yyyy.MM.dd") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// 날짜를 US 로케일로 지정된 형식의 문자열로 변환합니다.
    /// - Parameter format: 날짜 형식 (기본값: "yyyy.MM.dd")
    /// - Returns: 포맷된 날짜 문자열
    func formattedUS(_ format: String = "yyyy.MM.dd") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// 날짜를 "yyyy-MM-dd" 형식의 문자열로 변환합니다.
    /// - Returns: "yyyy-MM-dd" 형식의 날짜 문자열
    func toDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
