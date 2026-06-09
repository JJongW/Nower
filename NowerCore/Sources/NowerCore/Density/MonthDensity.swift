//
//  MonthDensity.swift
//  NowerCore
//
//  월별 밀도 집계. 일별 채점(DensityEngine) 위에 얹은 집계 레이어.
//  히트맵(날짜 칸 틴트)과 월 요약·패턴 감지에 쓴다. 순수 함수.
//

import Foundation

/// 하루치 밀도 요약 (월 집계의 한 칸)
public struct DayDensity: Sendable, Equatable {
    public let date: Date
    public let score: Int
    public let band: DensityBand
    /// 시간 일정 개수 (0이면 빈 날 — 히트맵에서 틴트 안 함)
    public let eventCount: Int

    public init(date: Date, score: Int, band: DensityBand, eventCount: Int) {
        self.date = date
        self.score = score
        self.band = band
        self.eventCount = eventCount
    }

    /// 시간 일정이 있어 밀도가 의미 있는 날인지
    public var hasLoad: Bool { eventCount > 0 }
}

/// 한 달 밀도 리포트
public struct MonthDensityReport: Sendable {
    /// 일정 있는 날들의 밀도 (날짜순)
    public let days: [DayDensity]
    /// 과부하/보통/여유 일수 (일정 있는 날 기준)
    public let heavyCount: Int
    public let moderateCount: Int
    public let lightCount: Int
    /// 가장 빡빡한 날
    public let heaviestDay: DayDensity?
    /// 요일별 평균 점수 (1=일 ... 7=토). 데이터 있는 요일만.
    public let weekdayAverages: [Int: Double]
    /// 평균이 가장 높은 요일 (1~7). 없으면 nil
    public let busiestWeekday: Int?
    /// 월 요약 narration
    public let narration: String

    public init(
        days: [DayDensity],
        heavyCount: Int,
        moderateCount: Int,
        lightCount: Int,
        heaviestDay: DayDensity?,
        weekdayAverages: [Int: Double],
        busiestWeekday: Int?,
        narration: String
    ) {
        self.days = days
        self.heavyCount = heavyCount
        self.moderateCount = moderateCount
        self.lightCount = lightCount
        self.heaviestDay = heaviestDay
        self.weekdayAverages = weekdayAverages
        self.busiestWeekday = busiestWeekday
        self.narration = narration
    }

    /// 날짜 → 밴드 빠른 조회 (히트맵 틴트용). 빈 날은 제외.
    public func band(forDateKey key: String) -> DensityBand? {
        bandLookup[key]
    }

    private var bandLookup: [String: DensityBand] {
        var map: [String: DensityBand] = [:]
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        for day in days where day.hasLoad {
            map[f.string(from: day.date)] = day.band
        }
        return map
    }
}

public enum MonthDensityEngine {

    /// 일별 입력 배열 → 월 리포트. 각 input.day가 그 날을 가리킨다.
    public static func score(_ inputs: [DensityInput], calendar: Calendar = .current) -> MonthDensityReport {
        let days: [DayDensity] = inputs.map { input in
            let report = DensityEngine.score(input)
            return DayDensity(
                date: input.day,
                score: report.score,
                band: report.band,
                eventCount: report.metrics.eventCount
            )
        }

        let loaded = days.filter { $0.hasLoad }

        let heavy = loaded.filter { $0.band == .heavy }.count
        let moderate = loaded.filter { $0.band == .moderate }.count
        let light = loaded.filter { $0.band == .light }.count
        let heaviest = loaded.max { $0.score < $1.score }

        // 요일별 평균 (1=일 ... 7=토)
        var byWeekday: [Int: [Int]] = [:]
        for day in loaded {
            let wd = calendar.component(.weekday, from: day.date)
            byWeekday[wd, default: []].append(day.score)
        }
        let averages: [Int: Double] = byWeekday.mapValues { scores in
            Double(scores.reduce(0, +)) / Double(scores.count)
        }
        let busiest = averages.max { $0.value < $1.value }?.key

        let narration = monthNarration(
            loadedCount: loaded.count,
            heavy: heavy,
            heaviest: heaviest,
            busiestWeekday: busiest,
            calendar: calendar
        )

        return MonthDensityReport(
            days: days,
            heavyCount: heavy,
            moderateCount: moderate,
            lightCount: light,
            heaviestDay: heaviest,
            weekdayAverages: averages,
            busiestWeekday: busiest,
            narration: narration
        )
    }

    private static let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

    private static func monthNarration(
        loadedCount: Int,
        heavy: Int,
        heaviest: DayDensity?,
        busiestWeekday: Int?,
        calendar: Calendar
    ) -> String {
        guard loadedCount > 0 else {
            return "이번 달은 시간 지정 일정이 거의 없어요."
        }

        var parts: [String] = []
        if heavy > 0 {
            parts.append("과부하 \(heavy)일")
        }
        if let wd = busiestWeekday, wd >= 1, wd <= 7 {
            parts.append("\(weekdayNames[wd - 1])요일이 가장 빡빡")
        }
        if let h = heaviest {
            let day = calendar.component(.day, from: h.date)
            parts.append("\(day)일이 최고치(\(h.score))")
        }

        if parts.isEmpty {
            return "이번 달은 전반적으로 여유로워요."
        }
        return "이번 달 " + parts.joined(separator: " · ") + "."
    }
}
