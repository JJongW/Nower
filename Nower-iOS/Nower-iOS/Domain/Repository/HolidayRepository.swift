//
//  HolidayRepository.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//



import Foundation

protocol HolidayRepository {
    func fetchHolidays(year: Int, month: Int, completion: @escaping ([Holiday]) -> Void)
    func isHoliday(dateString: String) -> Bool
    func holidayName(for dateString: String) -> String?
}
