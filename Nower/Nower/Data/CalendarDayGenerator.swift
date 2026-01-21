//
//  CalendarDayGenerator.swift
//  Nower
//
//  Created by 신종원 on 4/12/25.
//  Updated for week-based calendar on 5/12/25.
//

import Foundation

struct CalendarDayGenerator {
    /// iOS 버전과의 호환성을 위한 기존 메서드 (deprecated)
    /// 주별 달력으로 변경되었으므로 이 메서드는 더 이상 사용하지 않습니다.
    static func generate(for date: Date, todos: [TodoItem]) -> [CalendarDay] {
        // 주별로 생성한 후 CalendarDay로 변환 (하위 호환성)
        let weeks = generateWeeks(for: date, todos: todos)
        var days: [CalendarDay] = []
        
        for week in weeks {
            for dayInfo in week {
                if let day = dayInfo.day, !dayInfo.dateString.isEmpty {
                    days.append(CalendarDay(date: dayInfo.dateString, todos: dayInfo.todos))
                } else {
                    days.append(CalendarDay(date: "", todos: []))
                }
            }
        }
        
        return days
    }
    
    /// 주별 달력을 생성합니다. (iOS 버전과 동일)
    /// - Parameters:
    ///   - date: 기준 날짜
    ///   - todos: 모든 Todo 목록
    ///   - holidayNameProvider: 공휴일 이름을 제공하는 클로저 (선택적)
    /// - Returns: 주별로 그룹화된 날짜 정보 배열
    static func generateWeeks(
        for date: Date,
        todos: [TodoItem],
        holidayNameProvider: ((Date) -> String?)? = nil
    ) -> [[WeekDayInfo]] {
        var weeks: [[WeekDayInfo]] = []
        
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 월요일을 주의 시작으로 설정
        
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDayOfMonth = calendar.date(from: components) else {
            print("⚠️ [CalendarDayGenerator] 첫 번째 날짜를 생성할 수 없습니다")
            return weeks
        }
        
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekdayIndex = (weekday + 6) % 7 // 월요일 기준으로 변환
        
        let numberOfDays = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        
        // 첫 주 생성 (빈 날짜 + 실제 날짜)
        var currentWeek: [WeekDayInfo] = []
        
        // 빈 날짜들 추가
        for _ in 0..<firstWeekdayIndex {
            currentWeek.append(createEmptyDayInfo())
        }
        
        // 첫 주의 실제 날짜들 추가
        let daysInFirstWeek = 7 - firstWeekdayIndex
        for day in 1...daysInFirstWeek {
            let dayInfo = createDayInfo(
                day: day,
                components: components,
                calendar: calendar,
                todos: todos,
                today: today,
                formatter: formatter,
                holidayNameProvider: holidayNameProvider
            )
            currentWeek.append(dayInfo)
        }
        weeks.append(currentWeek)
        
        // 나머지 주들 생성
        var currentDay = daysInFirstWeek + 1
        while currentDay <= numberOfDays {
            currentWeek = []
            let daysInThisWeek = min(7, numberOfDays - currentDay + 1)
            
            for day in currentDay..<(currentDay + daysInThisWeek) {
                let dayInfo = createDayInfo(
                    day: day,
                    components: components,
                    calendar: calendar,
                    todos: todos,
                    today: today,
                    formatter: formatter,
                    holidayNameProvider: holidayNameProvider
                )
                currentWeek.append(dayInfo)
            }
            
            // 주가 7일이 안 되면 빈 날짜로 채움
            while currentWeek.count < 7 {
                currentWeek.append(createEmptyDayInfo())
            }
            
            weeks.append(currentWeek)
            currentDay += daysInThisWeek
        }
        
        return weeks
    }
    
    /// 날짜 정보를 생성합니다.
    private static func createDayInfo(
        day: Int,
        components: DateComponents,
        calendar: Calendar,
        todos: [TodoItem],
        today: Date,
        formatter: DateFormatter,
        holidayNameProvider: ((Date) -> String?)? = nil
    ) -> WeekDayInfo {
        var dayComponents = components
        dayComponents.day = day
        guard let date = calendar.date(from: dayComponents) else {
            return createEmptyDayInfo()
        }
        
        let dateString = formatter.string(from: date)
        
        // 해당 날짜의 Todo 필터링 (기간별 일정 포함)
        let dayTodos = todos.filter { todo in
            if todo.isPeriodEvent {
                return todo.includesDate(date)
            } else {
                return todo.date == dateString
            }
        }
        
        let isToday = calendar.isDate(today, inSameDayAs: date)
        let holidayName = holidayNameProvider?(date)
        let weekday = calendar.component(.weekday, from: date)
        let isSunday = weekday == 1
        let isSaturday = weekday == 7
        
        return WeekDayInfo(
            day: day,
            dateString: dateString,
            todos: dayTodos,
            isToday: isToday,
            isSelected: false,
            holidayName: holidayName,
            isSunday: isSunday,
            isSaturday: isSaturday
        )
    }
    
    /// 빈 날짜 정보를 생성합니다.
    private static func createEmptyDayInfo() -> WeekDayInfo {
        return WeekDayInfo(
            day: nil,
            dateString: "",
            todos: [],
            isToday: false,
            isSelected: false,
            holidayName: nil,
            isSunday: false,
            isSaturday: false
        )
    }
}

