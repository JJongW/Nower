//
//  HolidayUseCase.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation

/// 공휴일 조회를 담당하는 UseCase
/// macOS에서는 선택적 기능으로 제공됩니다.
protocol HolidayUseCase {
    /// 특정 연도와 월의 공휴일을 조회합니다.
    /// - Parameters:
    ///   - year: 연도
    ///   - month: 월
    ///   - completion: 완료 핸들러 (공휴일 배열 반환)
    func fetchHolidays(for year: Int, month: Int, completion: @escaping ([Holiday]) -> Void)
    
    /// 인접한 월의 공휴일을 미리 로드합니다.
    /// - Parameters:
    ///   - baseDate: 기준 날짜
    ///   - completion: 완료 핸들러 (선택적)
    func preloadAdjacentMonths(baseDate: Date, completion: (() -> Void)?)
    
    /// 특정 날짜의 공휴일 이름을 반환합니다.
    /// - Parameter date: 조회할 날짜
    /// - Returns: 공휴일 이름 (없으면 nil)
    func holidayName(for date: Date) -> String?
}
