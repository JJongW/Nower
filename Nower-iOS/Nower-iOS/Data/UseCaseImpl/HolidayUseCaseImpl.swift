//
//  HolidayUseCaseImpl.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation

final class HolidayUseCaseImpl: HolidayUseCase {
    private let repository: HolidayRepository

    init(repository: HolidayRepository) {
        self.repository = repository
    }

    func fetchHolidays(for year: Int, month: Int, completion: @escaping ([Holiday]) -> Void) {
        repository.fetchHolidays(year: year, month: month, completion: completion)
    }

    func preloadAdjacentMonths(baseDate: Date, completion: (() -> Void)?) {
        let calendar = Calendar.current
        let group = DispatchGroup()

        for offset in -2...2 {
            if let targetDate = calendar.date(byAdding: .month, value: offset, to: baseDate) {
                let components = calendar.dateComponents([.year, .month], from: targetDate)
                guard let year = components.year, let month = components.month else { continue }

                group.enter()
                repository.fetchHolidays(year: year, month: month) { _ in
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion?()
        }
    }

    func holidayName(for date: Date) -> String? {
        let key = date.toDateString()
        return repository.holidayName(for: key)
    }
}
