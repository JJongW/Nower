//
//  CalendarDataManager.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/21/25.
//

import Foundation

final class CalendarDataManager {
    private var holidayCache: [String: [Holiday]] = [:]
    static let shared = CalendarDataManager()
    private(set) var holidays: [String: String] = [:]

    func fetchHolidays(for year: Int, month: Int, completion: @escaping () -> Void) {
        let key = String(format: "%04d-%02d", year, month)

        if let cached = holidayCache[key] {
           applyToStorage(cached)
           completion()
           return
        }

        fetchHolidaysMoya(year: year, month: month) { holidays in
            self.holidayCache[key] = holidays
            DispatchQueue.main.async {
                self.applyToStorage(holidays)
                completion()
            }
        }
    }

    func preloadAdjacentMonths(baseDate: Date) {
        let calendar = Calendar.current
        for offset in -2...2 {
            if let date = calendar.date(byAdding: .month, value: offset, to: baseDate) {
                let comps = calendar.dateComponents([.year, .month], from: date)
                guard let year = comps.year, let month = comps.month else { continue }
                self.fetchHolidays(for: year, month: month) { }
            }
        }
    }

    private func applyToStorage(_ holidays: [Holiday]) {
        for holiday in holidays {
            if let date = formatAPIDate(holiday.locdateString) {
                let dateKey = formatDateForCoreData(from: date)
                self.holidays[dateKey] = holiday.dateName
            }
        }
    }

    private func formatAPIDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: dateString)
    }

    private func formatDateForCoreData(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func isHoliday(dateString: String) -> Bool {
        return holidays[dateString] != nil
    }

    func holidayName(for dateString: String) -> String? {
        return holidays[dateString]
    }
}
