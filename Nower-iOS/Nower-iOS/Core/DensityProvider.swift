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
    /// 예측 밀도(보정 전).
    static func report(todos: [TodoItem], day: Date) -> DensityReport {
        let events = todos.compactMap { $0.toDensityEvent(on: day) }
        return DensityEngine.score(DensityInput(day: day, events: events))
    }

    /// 개인 보정(회고 루프)을 반영한 밀도. reflections가 충분하면 점수·밴드가 보정된다.
    static func calibratedReport(todos: [TodoItem], day: Date, reflections: [DayReflection]) -> DensityReport {
        let base = report(todos: todos, day: day)
        let calibration = DensityCalibrator.calibration(from: reflections, asOf: day)
        return DensityCalibrator.apply(base, calibration: calibration)
    }

    static func viewState(todos: [TodoItem], day: Date) -> DensityViewState {
        DensityViewState(report: report(todos: todos, day: day))
    }

    /// 보정 반영 표시상태.
    static func calibratedViewState(todos: [TodoItem], day: Date, reflections: [DayReflection]) -> DensityViewState {
        DensityViewState(report: calibratedReport(todos: todos, day: day, reflections: reflections))
    }

    /// 자기상대 비교: 오늘 점수를 지난 30일 개인 분포에 대고 본다.
    /// todosProvider = 날짜별 일정 공급(VM.todos(for:)).
    static func comparison(
        todosProvider: (Date) -> [TodoItem],
        day: Date,
        reflections: [DayReflection]
    ) -> DensityComparison {
        let today = calibratedReport(todos: todosProvider(day), day: day, reflections: reflections)
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        var history: [DailyScore] = []
        for n in 1...RelativeDensityEngine.windowDays {
            guard let d = cal.date(byAdding: .day, value: -n, to: start) else { continue }
            let s = calibratedReport(todos: todosProvider(d), day: d, reflections: reflections).score
            history.append(DailyScore(date: d, score: s))
        }
        return RelativeDensityEngine.compare(todayScore: today.score, history: history, asOf: day, calendar: cal)
    }

    /// 자기상대 표현이 반영된 표시상태(칩/카드 의미가 "평소 대비"로 바뀜).
    static func relativeViewState(
        todosProvider: (Date) -> [TodoItem],
        day: Date,
        reflections: [DayReflection]
    ) -> DensityViewState {
        let report = calibratedReport(todos: todosProvider(day), day: day, reflections: reflections)
        let cmp = comparison(todosProvider: todosProvider, day: day, reflections: reflections)
        let callback = ReflectionCallbackEngine.callback(
            todayBand: report.band, reflections: reflections, asOf: day)
        let calibration = DensityCalibrator.calibration(from: reflections, asOf: day)
        let milestone = MilestoneEngine.newlyReached(
            comparison: cmp, calibration: calibration, shown: MilestoneStore.shownIDs()
        ).map(MilestoneCopy.text)
        return DensityViewState(report: report, comparison: cmp, reflectionCallback: callback, milestone: milestone)
    }

    /// 사용자가 상세 카드를 봤을 때 호출 — 현재 도달한 마일스톤을 '알림 완료'로 표시(다시 안 뜸).
    static func acknowledgeMilestones(
        todosProvider: (Date) -> [TodoItem],
        day: Date,
        reflections: [DayReflection]
    ) {
        let cmp = comparison(todosProvider: todosProvider, day: day, reflections: reflections)
        let calibration = DensityCalibrator.calibration(from: reflections, asOf: day)
        let reached = MilestoneEngine.allReached(comparison: cmp, calibration: calibration)
        MilestoneStore.markShown(reached.map(\.id))
    }

    /// 월별 밀도 집계. days = 그 달의 날짜들, todosProvider = 날짜별 일정 공급.
    static func monthReport(days: [Date], todosProvider: (Date) -> [TodoItem]) -> MonthDensityReport {
        let inputs = days.map { day in
            DensityInput(day: day, events: todosProvider(day).compactMap { $0.toDensityEvent(on: day) })
        }
        return MonthDensityEngine.score(inputs)
    }

    /// 월간 에너지 리포트(예측 집계 + 체감 종합 + 처방).
    static func monthlyEnergyReport(
        month: Date,
        days: [Date],
        todosProvider: (Date) -> [TodoItem],
        reflections: [DayReflection]
    ) -> MonthlyEnergyReport {
        let density = monthReport(days: days, todosProvider: todosProvider)
        let calibration = DensityCalibrator.calibration(from: reflections, asOf: month)
        return MonthlyEnergyReportEngine.make(
            month: month,
            density: density,
            reflections: reflections,
            calibration: calibration
        )
    }
}

#endif
