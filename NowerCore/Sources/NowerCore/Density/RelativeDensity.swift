//
//  RelativeDensity.swift
//  NowerCore
//
//  "자기 상대(self-relative)" 표현 레이어 — 절대 점수(0~100)를 사용자 자신의
//  최근 분포에 대고 비교해 "평소보다 무거움/비슷/가벼움"으로 옮긴다.
//  입력 성실도와 무관하게 "정도"가 의미를 갖게 하는 핵심(같은 사람 분포 기준).
//
//  하이브리드 기준선(grilling 합의):
//    표본 부족 → 콜드스타트(절대 밴드) → 최근 30일 개인 분포 → 같은 요일 보정.
//  순수 함수, 온디바이스. "근거 없는 점수 안 띄운다" — basis/표본수를 함께 노출.
//

import Foundation

/// 하루치 밀도 점수 한 점 (자기 상대 비교의 입력 이력)
public struct DailyScore: Sendable, Equatable {
    public let date: Date
    public let score: Int
    public init(date: Date, score: Int) {
        self.date = date
        self.score = score
    }
}

/// 자기 상대 밴드 — 나의 평소 대비
public enum RelativeBand: String, Sendable, Equatable {
    case lighter   // 평소보다 가벼움
    case typical   // 평소만큼
    case heavier   // 평소보다 무거움
}

/// 비교가 어떤 근거로 이뤄졌는지 (투명성)
public enum ComparisonBasis: Sendable, Equatable {
    case coldStart           // 표본 부족 → 절대 밴드로 대체
    case recent(days: Int)   // 최근 N일 개인 분포
    case weekday(String)     // 같은 요일 분포 (요일명)
}

/// 자기 상대 비교 결과
public struct DensityComparison: Sendable, Equatable {
    public let todayScore: Int
    public let relativeBand: RelativeBand
    public let basis: ComparisonBasis
    /// 비교에 쓰인 표본 수(활동한 날 기준)
    public let sampleCount: Int
    /// 비교 기준이 된 개인 중앙값(콜드스타트면 nil)
    public let personalMedian: Int?

    public init(todayScore: Int, relativeBand: RelativeBand, basis: ComparisonBasis,
                sampleCount: Int, personalMedian: Int?) {
        self.todayScore = todayScore
        self.relativeBand = relativeBand
        self.basis = basis
        self.sampleCount = sampleCount
        self.personalMedian = personalMedian
    }
}

public enum RelativeDensityEngine {

    /// 개인 분포로 전환하는 최소 활동일 수
    public static let minSamples = 5
    /// 같은 요일 보정을 켜는 최소 같은-요일 표본
    public static let minWeekdaySamples = 3
    /// 개인 분포를 보는 창(일)
    public static let windowDays = 30

    /// 오늘 점수를 최근 이력에 대고 자기 상대로 분류.
    /// - Parameters:
    ///   - todayScore: 오늘 밀도 점수(0~100, 보정 후)
    ///   - history: 과거 일별 점수(오늘 이전). 빈 날(0점)은 "평소" 분모에서 제외.
    ///   - asOf: 기준 날짜(오늘)
    public static func compare(
        todayScore: Int,
        history: [DailyScore],
        asOf: Date,
        calendar: Calendar = .current
    ) -> DensityComparison {
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: asOf) else {
            return coldStart(todayScore)
        }
        let today0 = calendar.startOfDay(for: asOf)

        // 창 안 + 오늘 이전 + 활동한 날(score>0)만 "평소"로
        let active = history.filter {
            let d = calendar.startOfDay(for: $0.date)
            return d >= calendar.startOfDay(for: windowStart) && d < today0 && $0.score > 0
        }

        guard active.count >= minSamples else { return coldStart(todayScore) }

        // 같은 요일 표본이 충분하면 요일 분포로 보정(더 정교)
        let weekday = calendar.component(.weekday, from: asOf)
        let sameWeekday = active.filter { calendar.component(.weekday, from: $0.date) == weekday }
        if sameWeekday.count >= minWeekdaySamples {
            let scores = sameWeekday.map(\.score)
            return classify(todayScore, against: scores,
                            basis: .weekday(weekdayName(weekday)), sampleCount: scores.count)
        }

        let scores = active.map(\.score)
        return classify(todayScore, against: scores,
                        basis: .recent(days: windowDays), sampleCount: scores.count)
    }

    // MARK: - 분류

    /// 분포의 33/67 백분위로 lighter/typical/heavier 구분.
    private static func classify(_ today: Int, against scores: [Int],
                                 basis: ComparisonBasis, sampleCount: Int) -> DensityComparison {
        let sorted = scores.sorted()
        let p33 = percentile(sorted, 0.33)
        let p67 = percentile(sorted, 0.67)
        let band: RelativeBand
        if today <= p33 { band = .lighter }
        else if today >= p67 { band = .heavier }
        else { band = .typical }
        return DensityComparison(todayScore: today, relativeBand: band, basis: basis,
                                 sampleCount: sampleCount, personalMedian: median(sorted))
    }

    private static func coldStart(_ today: Int) -> DensityComparison {
        // 표본 부족 → 절대 밴드를 자기상대 밴드로 매핑(거친 근사)
        let band: RelativeBand
        switch DensityBand(score: today) {
        case .light: band = .lighter
        case .moderate: band = .typical
        case .heavy: band = .heavier
        }
        return DensityComparison(todayScore: today, relativeBand: band, basis: .coldStart,
                                 sampleCount: 0, personalMedian: nil)
    }

    // MARK: - 통계 헬퍼

    /// 선형보간 백분위 (sorted 비어있으면 0)
    static func percentile(_ sorted: [Int], _ p: Double) -> Int {
        guard !sorted.isEmpty else { return 0 }
        guard sorted.count > 1 else { return sorted[0] }
        let rank = p * Double(sorted.count - 1)
        let lo = Int(rank.rounded(.down))
        let hi = Int(rank.rounded(.up))
        let frac = rank - Double(lo)
        return Int((Double(sorted[lo]) * (1 - frac) + Double(sorted[hi]) * frac).rounded())
    }

    static func median(_ sorted: [Int]) -> Int { percentile(sorted, 0.5) }

    private static func weekdayName(_ weekday: Int) -> String {
        let names = ["일", "월", "화", "수", "목", "금", "토"]
        guard weekday >= 1, weekday <= 7 else { return "" }
        return names[weekday - 1]
    }
}

/// 자기 상대 비교 → 사용자 카피. 원칙: 숫자는 비교 안에서만, 모르면 모른다고.
public enum RelativeDensityCopy {

    /// 칩용 짧은 라벨 ("평소보다 빡빡해요" 등) — 여유 어휘.
    public static func chipLabel(_ c: DensityComparison) -> String {
        switch (c.basis, c.relativeBand) {
        case (.coldStart, _):
            // 아직 '평소'를 모름 → 절대 밴드 라벨로 정직하게
            return DensityBand(score: c.todayScore).label
        case (.weekday(let wd), .heavier): return "\(wd)요일치곤 빡빡해요"
        case (.weekday(let wd), .lighter): return "\(wd)요일치곤 넉넉해요"
        case (.weekday(let wd), .typical): return "여느 \(wd)요일만큼"
        case (_, .heavier): return "평소보다 빡빡해요"
        case (_, .lighter): return "평소보다 넉넉해요"
        case (_, .typical): return "평소만큼"
        }
    }

    /// 카드용 한 줄 의미. 여유 어휘. 콜드스타트는 정직한 안내.
    public static func meaning(_ c: DensityComparison) -> String {
        switch c.basis {
        case .coldStart:
            return "아직 ‘평소’를 가늠할 만큼 기록이 쌓이지 않았어요. 며칠 더 보면 너에게 맞게 짚어드릴게요."
        case .recent:
            switch c.relativeBand {
            case .heavier: return "최근 \(c.sampleCount)일과 견주면 여유가 빡빡한 하루예요."
            case .lighter: return "최근 \(c.sampleCount)일과 견주면 여유로운 하루예요."
            case .typical: return "최근 너의 흐름과 비슷한 하루예요."
            }
        case .weekday(let wd):
            switch c.relativeBand {
            case .heavier: return "여느 \(wd)요일보다 여유가 빠듯한 하루예요."
            case .lighter: return "여느 \(wd)요일보다 여유로운 하루예요."
            case .typical: return "딱 너의 \(wd)요일다운 하루예요."
            }
        }
    }
}
