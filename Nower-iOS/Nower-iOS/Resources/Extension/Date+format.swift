//
//  Date+format.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/20/25.
//

import Foundation

extension Date {
    func formatted(_ format: String = "yyyy.MM.dd") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func formattedUS(_ format: String = "yyyy.MM.dd") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func toDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
