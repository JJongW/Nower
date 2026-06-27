//
//  NarrationBuilder.swift
//  NowerCore
//
//  밀도 점수를 "근거 → 의미 → 처방"으로 옮기는 룰 기반 레이어.
//  raw 측정값(DensityMetrics)을 절대 기준(DensityAnchor)과 비교해
//  왜 이 점수인지, 무슨 뜻인지, 뭘 조정하면 되는지를 만든다.
//  v1 룰/템플릿 기반(프라이버시 100%). v2에서 LLM 표현 레이어로 교체 가능.
//

import Foundation

enum NarrationBuilder {

    // MARK: - 의미 (점수 한 줄 해석)

    /// 이 밴드 점수가 무슨 뜻인지 — 기준 대비 한 줄.
    static func meaning(band: DensityBand, metrics: DensityMetrics) -> String {
        switch band {
        case .light:
            return "여유로운 하루예요. 일정이 적고 집중할 시간이 충분해요."
        case .moderate:
            return "적당히 채워진 하루예요. 무리는 아니지만 틈이 빡빡해질 수 있어요."
        case .heavy:
            return "과부하 신호예요. 전환·이동·끊김이 겹쳐 쉽게 지칠 수 있는 하루예요."
        }
    }

    // MARK: - narration (근거 인용 1~2줄)

    /// "{밴드}. {1순위 근거}. {2순위 근거}" — 측정값을 기준과 비교해 인용.
    static func narrate(score: Int, band: DensityBand, signals: [SignalScore], metrics: DensityMetrics) -> String {
        guard let top = signals.first, top.contribution > 0 else {
            return "오늘은 부담이 거의 없는 하루예요."
        }

        var sentences: [String] = [evidence(for: top.signal, metrics: metrics)]

        // 두 번째 신호 기여가 크면 근거 한 줄 더
        if signals.count > 1, signals[1].contribution >= 0.15 {
            sentences.append(evidence(for: signals[1].signal, metrics: metrics))
        }

        return sentences.joined(separator: " ")
    }

    /// 신호별 raw 근거 문장 (기준 대비 비교 포함)
    private static func evidence(for signal: DensitySignal, metrics: DensityMetrics) -> String {
        switch signal {
        case .occupancy:
            let h = Double(metrics.bookedMinutes) / 60.0
            if metrics.bookedMinutes >= DensityAnchor.fullDayBookedMinutes {
                return String(format: "시간 일정이 %.1f시간이라 하루가 꽉 차 있어요.", h)
            }
            return String(format: "시간 일정이 %.1f시간 잡혀 있어요.", h)

        case .transitions:
            let n = metrics.eventCount
            if n >= DensityAnchor.busyEventCount {
                return "일정이 \(n)개로 보통(3~4개)보다 많아 전환이 잦아요."
            }
            return "일정 \(n)개가 흩어져 전환이 생겨요."

        case .focusFragmentation:
            let block = metrics.largestFocusBlockMinutes
            if block < DensityAnchor.recommendedFocusBlock {
                return "가장 긴 집중 시간이 \(block)분뿐이라(권장 \(DensityAnchor.recommendedFocusBlock)분) 깊은 작업이 어려워요."
            }
            return "집중 블록은 \(block)분으로 확보돼 있어요."

        case .socialLoad:
            return "대면 일정이 \(metrics.inPersonCount)건 몰려 에너지 소모가 커요."

        case .travelLoad:
            let m = metrics.travelMinutes ?? 0
            return "일정 사이 이동이 \(m)분이라 여유 시간이 줄어요."

        case .sleepConflict:
            let h = metrics.sleepHours ?? 0
            let start = metrics.firstEventHour.map { hourString($0) } ?? "오전"
            return String(format: "어젯밤 수면이 %.1f시간인데 첫 일정이 %@이라 컨디션이 받쳐주기 어려워요.", h, start)

        case .commitmentLoad:
            let n = metrics.allDayCount
            if n >= DensityAnchor.busyCommitmentCount {
                return "종일·기간 일정이 \(n)건이나 겹쳐 하루 전체가 묶여 있어요."
            }
            return "종일·기간 일정이 \(n)건 잡혀 있어요."
        }
    }

    // MARK: - 처방 (행동 제안 1개, 근거 기반)

    /// 가장 기여 큰 신호를 줄이는 구체 행동. value 0.4 이상일 때만.
    static func suggest(signals: [SignalScore], metrics: DensityMetrics, events: [Event], input: DensityInput) -> ActionSuggestion? {
        guard let top = signals.first, top.value >= 0.4 else { return nil }

        switch top.signal {
        case .occupancy:
            // 점유 자체는 "줄이라"는 처방이 어색 — 2순위 인지부하 신호로 제안을 넘긴다.
            let next = signals.dropFirst().first { $0.signal != .occupancy && $0.value >= 0.4 }
            guard let next else { return nil }
            return suggest(signals: [next] + signals.filter { $0.signal != next.signal && $0.signal != .occupancy },
                           metrics: metrics, events: events, input: input)

        case .focusFragmentation:
            // 가장 짧은 빈틈을 만든 일정 시각을 짚어 "그 일정을 옮기면 블록이 생긴다"
            if let breaker = focusBreaker(events) {
                let t = timeString(breaker.startDateTime, calendar: input.calendar)
                return ActionSuggestion(
                    signal: .focusFragmentation,
                    message: "집중 시간이 \(metrics.largestFocusBlockMinutes)분뿐이에요. \(t) 일정을 앞뒤로 붙이면 더 긴 연속 블록이 생겨요."
                )
            }
            return ActionSuggestion(
                signal: .focusFragmentation,
                message: "한 일정을 옮겨 \(DensityAnchor.recommendedFocusBlock)분 이상 연속 블록을 만들어보세요."
            )

        case .transitions:
            return ActionSuggestion(
                signal: .transitions,
                message: "일정 \(metrics.eventCount)개가 흩어져 있어요. 비슷한 일정끼리 시간을 모으면 전환이 줄어요."
            )

        case .travelLoad:
            return ActionSuggestion(
                signal: .travelLoad,
                message: "이동이 \(metrics.travelMinutes ?? 0)분이에요. 같은 동선의 일정을 붙이면 이동을 아낄 수 있어요."
            )

        case .socialLoad:
            return ActionSuggestion(
                signal: .socialLoad,
                message: "대면 \(metrics.inPersonCount)건이 연달아 있어요. 사이에 짧은 회복 시간을 넣어두면 덜 지쳐요."
            )

        case .sleepConflict:
            return ActionSuggestion(
                signal: .sleepConflict,
                message: "수면이 부족한데 일정이 일러요. 오전 일정을 조금 미룰 수 있는지 살펴보세요."
            )

        case .commitmentLoad:
            return ActionSuggestion(
                signal: .commitmentLoad,
                message: "종일·기간 일정이 \(metrics.allDayCount)건이에요. 오늘 꼭 해야 하는 건지 한 번 추려보세요."
            )
        }
    }

    // MARK: - 헬퍼

    /// 집중을 가장 많이 깨는 일정 = 가장 짧은 양수 빈틈 뒤에 오는 일정
    private static func focusBreaker(_ events: [Event]) -> Event? {
        guard events.count > 1 else { return nil }
        var best: (gap: TimeInterval, event: Event)?
        for i in 1..<events.count {
            let gap = events[i].startDateTime.timeIntervalSince(events[i - 1].endDateTime)
            guard gap > 0 else { continue }
            if best == nil || gap < best!.gap {
                best = (gap, events[i])
            }
        }
        return best?.event
    }

    private static func timeString(_ date: Date, calendar: Calendar) -> String {
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        return m == 0 ? "\(h)시" : String(format: "%d:%02d", h, m)
    }

    private static func hourString(_ hour: Double) -> String {
        let h = Int(hour)
        let m = Int((hour - Double(h)) * 60)
        return m == 0 ? "\(h)시" : String(format: "%d:%02d", h, m)
    }
}
