//
//  DensityProvider.swift
//  Nower-iOS
//
//  앱의 TodoItem 데이터 → NowerCore 밀도 엔진 입력으로 변환.
//  EventKit/HealthKit/MapKit 미사용 — 앱 자체 일정만 사용(v1).
//  수면/이동 신호는 nil → 엔진이 graceful degrade (전환/집중/대면 신호로 채점).
//

import Foundation

#if canImport(NowerCore)
import NowerCore

extension TodoItem {
    /// 밀도 계산용 시간 기반 Event로 변환.
    /// 시간 없는(하루 종일) 일정은 nil — 엔진이 어차피 종일 일정은 무시한다.
    func toDensityEvent(on day: Date) -> NowerCore.Event? {
        let theme = NowerCore.ColorTheme.from(legacyColorName: colorName)

        // 시간 있는 일정 → 조회한 day에 시각 결합 (기간/반복도 그 날에 앵커)
        if let timeStr = scheduledTime,
           let start = TodoItem.combineTime(timeStr, with: day) {
            let end: Date
            if let endStr = endScheduledTime,
               let parsed = TodoItem.combineTime(endStr, with: day),
               parsed > start {
                end = parsed
            } else {
                end = start.addingTimeInterval(3600) // 종료 시간 없으면 기본 1시간
            }
            return NowerCore.Event(
                id: id, title: text, colorTheme: theme,
                startDateTime: start, endDateTime: end,
                isAllDay: false, timeZone: .current
            )
        }

        // 시간 없는 종일/기간 일정 → 약속 부하로 집계되도록 종일 Event로
        let startOfDay = Calendar.current.startOfDay(for: day)
        let endOfDay = startOfDay.addingTimeInterval(86_399)
        return NowerCore.Event(
            id: id, title: text, colorTheme: theme,
            startDateTime: startOfDay, endDateTime: endOfDay,
            isAllDay: true, timeZone: .current
        )
    }

    /// "HH:mm" 문자열을 기준 날짜에 결합
    static func combineTime(_ time: String, with day: Date) -> Date? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: day)
    }
}

/// 밀도 리포트/표시상태 진입점
enum NowerDensity {
    static func report(todos: [TodoItem], day: Date) -> DensityReport {
        let events = todos.compactMap { $0.toDensityEvent(on: day) }
        return DensityEngine.score(DensityInput(day: day, events: events))
    }

    static func viewState(todos: [TodoItem], day: Date) -> DensityViewState {
        DensityViewState(report: report(todos: todos, day: day))
    }

    /// 월별 밀도 집계. days = 그 달의 날짜들, todosProvider = 날짜별 일정 공급.
    static func monthReport(days: [Date], todosProvider: (Date) -> [TodoItem]) -> MonthDensityReport {
        let inputs = days.map { day in
            DensityInput(day: day, events: todosProvider(day).compactMap { $0.toDensityEvent(on: day) })
        }
        return MonthDensityEngine.score(inputs)
    }
}

#endif
