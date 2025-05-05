//
//  CalendarDataManager.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/21/25.
//

import Foundation
import Moya

final class HolidayRepositoryImpl: HolidayRepository {

    // MARK: - Caching
    private var holidayCache: [String: [Holiday]] = [:]              // "2025-05" -> [Holiday]
    private var holidaysByDateString: [String: String] = [:]         // "2025-05-05" -> "어린이날"

    private let apiClient = HolidayAPIClient()

    // MARK: - Public Methods

    func fetchHolidays(year: Int, month: Int, completion: @escaping ([Holiday]) -> Void) {
        let key = String(format: "%04d-%02d", year, month)

        if let cached = holidayCache[key] {
            applyToStorage(cached)
            completion(cached)
            return
        }

        fetchHolidaysFromAPI(year: year, month: month) { [weak self] holidays in
            guard let self = self else { return }
            self.holidayCache[key] = holidays
            self.applyToStorage(holidays)
            completion(holidays)
        }
    }

    func holidayName(for dateString: String) -> String? {
        return holidaysByDateString[dateString]
    }

    func isHoliday(dateString: String) -> Bool {
        return holidaysByDateString.keys.contains(dateString)
    }

    // MARK: - Private Helpers

    private func fetchHolidaysFromAPI(year: Int, month: Int, completion: @escaping ([Holiday]) -> Void) {
        apiClient.fetchHolidays(year: year, month: month) { result in
            switch result {
            case .success(let holidays):
                completion(holidays)
            case .failure(_):
                completion([])
            }
        }
    }

    private func applyToStorage(_ holidays: [Holiday]) {
        for holiday in holidays {
            if let date = formatAPIDate(holiday.locdateString) {
                let dateKey = formatDateForKey(date)
                holidaysByDateString[dateKey] = holiday.dateName
            }
        }
    }

    private func formatAPIDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: dateString)
    }

    private func formatDateForKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
