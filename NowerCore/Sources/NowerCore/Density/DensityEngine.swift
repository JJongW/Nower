//
//  DensityEngine.swift
//  NowerCore
//
//  하루 밀도 계산 엔진. 순수 함수 — 같은 입력 → 같은 출력.
//  플랫폼 프레임워크 의존 없음. iOS/macOS 공유.
//
//  5개 신호를 0~1로 측정 → 가중 합성 → 0~100 점수.
//  데이터 없는 신호(수면/이동)는 제외하고 가중치 재분배(graceful degrade).
//

import Foundation

public enum DensityEngine {

    /// 신호별 기본 가중치 (제공된 신호끼리 정규화됨).
    /// occupancy(점유)가 기둥 — 가장 큰 가중치. 나머지는 인지 부하 보조.
    private static let baseWeights: [DensitySignal: Double] = [
        .occupancy: 0.35,
        .travelLoad: 0.18,
        .socialLoad: 0.12,
        .commitmentLoad: 0.12,
        .transitions: 0.10,
        .focusFragmentation: 0.10,
        .sleepConflict: 0.10
    ]

    /// 하루 밀도 리포트 산출
    public static func score(_ input: DensityInput) -> DensityReport {
        let timed = timedEvents(input)
        let allDay = allDayEvents(input)

        // 시간 일정도 종일 일정도 없으면 빈 하루
        guard !timed.isEmpty || !allDay.isEmpty else {
            return DensityReport(
                score: 0,
                band: .light,
                signals: [],
                meaning: "등록된 일정이 없는 하루예요.",
                narration: "오늘은 일정이 없어요. 온전히 비어 있는 하루예요.",
                suggestion: nil,
                metrics: .empty
            )
        }

        // 각 신호 측정 (제공 불가 신호는 nil)
        var raw: [(signal: DensitySignal, value: Double, detail: String)] = []
        // 점유는 항상 포함 — 시간 일정이 없으면 value 0(종일-only 날에 commitment가 점수를 지배하지 않게 누름)
        raw.append(occupancySignal(timed))
        if !timed.isEmpty {
            raw.append(transitionsSignal(timed))
            raw.append(focusSignal(timed, input: input))
            // 대면 데이터(위치) 없으면 제외 — travel/sleep과 동일한 graceful degrade
            if let social = socialSignal(timed) { raw.append(social) }
            if let travel = travelSignal(input) { raw.append(travel) }
            if let sleep = sleepSignal(timed, input: input) { raw.append(sleep) }
        }
        if !allDay.isEmpty { raw.append(commitmentSignal(allDay)) }

        // 가중치 재정규화 (제공된 신호만)
        let totalBase = raw.reduce(0.0) { $0 + (baseWeights[$1.signal] ?? 0) }
        let signals: [SignalScore] = raw.map { item in
            let w = totalBase > 0 ? (baseWeights[item.signal] ?? 0) / totalBase : 0
            return SignalScore(signal: item.signal, value: item.value, weight: w, detail: item.detail)
        }
        .sorted { $0.contribution > $1.contribution }

        let scoreValue = signals.reduce(0.0) { $0 + $1.contribution }
        let score = Int((scoreValue * 100).rounded())
        let band = DensityBand(score: score)

        let metrics = self.metrics(timed, allDay: allDay, input: input)
        let meaning = NarrationBuilder.meaning(band: band, metrics: metrics)
        let narration = NarrationBuilder.narrate(score: score, band: band, signals: signals, metrics: metrics)
        let suggestion = NarrationBuilder.suggest(signals: signals, metrics: metrics, events: timed, input: input)

        return DensityReport(
            score: score,
            band: band,
            signals: signals,
            meaning: meaning,
            narration: narration,
            suggestion: suggestion,
            metrics: metrics
        )
    }

    /// 채점 근거 raw 측정값 계산
    static func metrics(_ timed: [Event], allDay: [Event], input: DensityInput) -> DensityMetrics {
        let gaps = freeGaps(timed)
        let positiveGaps = gaps.filter { $0 > 0 }
        let largestBlockMin = Int((gaps.max() ?? 0) / 60)
        let smallGaps = gaps.filter { $0 > 0 && $0 < 3600 }.count
        let tightest = positiveGaps.min().map { Int($0 / 60) }
        let inPerson = timed.filter { $0.location != nil }.count

        let firstHour: Double? = timed.first.map {
            let h = input.calendar.component(.hour, from: $0.startDateTime)
            let m = input.calendar.component(.minute, from: $0.startDateTime)
            return Double(h) + Double(m) / 60.0
        }
        let travel: Int? = input.travel.isEmpty
            ? nil
            : Int(input.travel.reduce(0.0) { $0 + $1.travelMinutes })

        return DensityMetrics(
            eventCount: timed.count,
            bookedMinutes: bookedMinutes(timed),
            allDayCount: allDay.count,
            largestFocusBlockMinutes: largestBlockMin,
            smallGapCount: smallGaps,
            tightestGapMinutes: tightest,
            inPersonCount: inPerson,
            firstEventHour: firstHour,
            travelMinutes: travel,
            sleepHours: input.sleep?.asleepHours
        )
    }

    // MARK: - 일정 추출

    /// 그날의 시간 기반 일정만, 시작순 정렬 (하루 종일 제외).
    /// "그 날짜에 속하는가"로 거른다 — input.day의 시각 성분에 의존하지 않음.
    /// (includesDate(순간)은 '그 순간 진행 중'을 뜻해 다른 의미라 쓰지 않는다)
    static func timedEvents(_ input: DensityInput) -> [Event] {
        input.events
            .filter { event in
                guard !event.isAllDay else { return false }
                return input.calendar.isDate(event.startDateTime, inSameDayAs: input.day)
            }
            .sorted { $0.startDateTime < $1.startDateTime }
    }

    /// 그날의 종일/기간 일정 (그 날짜에 걸치는 것)
    static func allDayEvents(_ input: DensityInput) -> [Event] {
        input.events.filter { event in
            guard event.isAllDay else { return false }
            return event.includesDate(input.day)
        }
    }

    // MARK: - 신호 측정 (각 0...1)

    /// 점유: 시간 일정이 하루를 묶은 총 시간(겹침은 병합). 6시간에서 포화.
    /// 밀도의 기둥 — 일정이 없으면 0(반박 불가능한 "비어 있음").
    static func occupancySignal(_ events: [Event]) -> (DensitySignal, Double, String) {
        let mins = bookedMinutes(events)
        let value = min(1.0, Double(mins) / Double(DensityAnchor.fullDayBookedMinutes))
        let h = Double(mins) / 60.0
        let detail = mins == 0 ? "묶인 시간 없음" : String(format: "일정 %.1f시간", h)
        return (.occupancy, value, detail)
    }

    /// 전환: 일정 개수가 많을수록 컨텍스트 스위치 증가. 8개에서 포화.
    static func transitionsSignal(_ events: [Event]) -> (DensitySignal, Double, String) {
        let count = events.count
        let value = min(1.0, Double(count) / 8.0)
        return (.transitions, value, "전환 \(count)회")
    }

    /// 집중 분절: 무중단 집중 블록 확보 정도.
    /// 가장 긴 빈 블록이 짧고, 짧은 빈틈(<60분)이 많을수록 부담.
    static func focusSignal(_ events: [Event], input: DensityInput) -> (DensitySignal, Double, String) {
        let gaps = freeGaps(events)
        let largestBlockMin = (gaps.max() ?? 0) / 60
        let smallGaps = gaps.filter { $0 > 0 && $0 < 3600 }.count

        // 3시간 무중단 블록이면 분절 없음(0), 0분이면 최대(1)
        let blockPenalty = 1.0 - min(1.0, largestBlockMin / 180.0)
        let fragmentPenalty = min(1.0, Double(smallGaps) / 4.0)
        let value = (blockPenalty + fragmentPenalty) / 2.0

        let blockHours = largestBlockMin / 60
        let detail = String(format: "최대 집중 %.1fh · 짧은 빈틈 %d개", blockHours, smallGaps)
        return (.focusFragmentation, value, detail)
    }

    /// 사회 부하: 대면(위치 있는) 일정 수 + 연속 대면.
    /// (Event에 참석자 필드가 없어 location 유무로 근사 — PRD 명시)
    /// 위치 데이터가 하나도 없으면 nil → 신호 제외(graceful degrade).
    /// 항상 0으로 포함되면 시간 일정 점수를 부당하게 깎으므로.
    static func socialSignal(_ events: [Event]) -> (DensitySignal, Double, String)? {
        let inPerson = events.filter { $0.location != nil }
        guard !inPerson.isEmpty else { return nil }
        let count = inPerson.count
        let streak = longestInPersonStreak(events)
        // 대면 5건에서 포화, 연속 3건 이상이면 가중
        let base = min(1.0, Double(count) / 5.0)
        let streakBonus = streak >= 3 ? 0.2 : 0.0
        let value = min(1.0, base + streakBonus)
        return (.socialLoad, value, "대면 \(count)건 · 최장 연속 \(streak)건")
    }

    /// 이동 부하: 이동 시간 합 (2시간에서 포화). travel 없으면 nil.
    static func travelSignal(_ input: DensityInput) -> (DensitySignal, Double, String)? {
        guard !input.travel.isEmpty else { return nil }
        let totalMin = input.travel.reduce(0.0) { $0 + $1.travelMinutes }
        let value = min(1.0, totalMin / 120.0)
        return (.travelLoad, value, "이동 \(Int(totalMin))분")
    }

    /// 수면 충돌: 짧은 수면 + 이른 첫 일정. sleep 없으면 nil.
    static func sleepSignal(_ events: [Event], input: DensityInput) -> (DensitySignal, Double, String)? {
        guard let sleep = input.sleep else { return nil }

        // 7시간 미만 수면을 결핍으로
        let deficit = max(0.0, (7.0 - sleep.asleepHours) / 7.0)

        // 첫 일정이 오전 9시 이전이면 이른 시작 페널티
        var earlyPenalty = 0.0
        if let first = events.first {
            let hour = input.calendar.component(.hour, from: first.startDateTime)
            let minute = input.calendar.component(.minute, from: first.startDateTime)
            let startHour = Double(hour) + Double(minute) / 60.0
            if startHour < 9.0 {
                earlyPenalty = min(1.0, (9.0 - startHour) / 3.0) // 6시 이전이면 최대
            }
        }

        let value = min(1.0, deficit * 0.7 + earlyPenalty * 0.3)
        let detail = String(format: "수면 %.1fh", sleep.asleepHours)
        return (.sleepConflict, value, detail)
    }

    /// 약속 부하: 종일/기간 일정 건수. 3건에서 포화.
    static func commitmentSignal(_ allDay: [Event]) -> (DensitySignal, Double, String) {
        let count = allDay.count
        let value = min(1.0, Double(count) / Double(DensityAnchor.busyCommitmentCount))
        return (.commitmentLoad, value, "종일/기간 \(count)건")
    }

    // MARK: - 헬퍼

    /// 시간 일정이 점유한 총 시간(분). 겹치는 구간은 union으로 병합해 이중 집계 방지.
    static func bookedMinutes(_ events: [Event]) -> Int {
        guard !events.isEmpty else { return 0 }
        let sorted = events.sorted { $0.startDateTime < $1.startDateTime }
        var total: TimeInterval = 0
        var curStart = sorted[0].startDateTime
        var curEnd = sorted[0].endDateTime
        for e in sorted.dropFirst() {
            if e.startDateTime > curEnd {
                total += curEnd.timeIntervalSince(curStart)
                curStart = e.startDateTime
                curEnd = e.endDateTime
            } else if e.endDateTime > curEnd {
                curEnd = e.endDateTime
            }
        }
        total += curEnd.timeIntervalSince(curStart)
        return Int(total / 60)
    }

    /// 인접 일정 사이의 빈 시간(초) 배열. 겹치면 0.
    static func freeGaps(_ events: [Event]) -> [TimeInterval] {
        guard events.count > 1 else { return [] }
        var gaps: [TimeInterval] = []
        for i in 1..<events.count {
            let gap = events[i].startDateTime.timeIntervalSince(events[i - 1].endDateTime)
            gaps.append(max(0, gap))
        }
        return gaps
    }

    /// 위치 있는(대면) 일정의 최장 연속 길이
    static func longestInPersonStreak(_ events: [Event]) -> Int {
        var best = 0
        var current = 0
        for e in events {
            if e.location != nil {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }
}
