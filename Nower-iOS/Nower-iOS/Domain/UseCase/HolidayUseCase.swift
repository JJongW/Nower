//
//  HolidayUseCase.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//
import Foundation

protocol HolidayUseCase {
    func fetchHolidays(for year: Int, month: Int, completion: @escaping ([Holiday]) -> Void)
    func preloadAdjacentMonths(baseDate: Date, completion: (() -> Void)?)
    func holidayName(for date: Date) -> String?
}
