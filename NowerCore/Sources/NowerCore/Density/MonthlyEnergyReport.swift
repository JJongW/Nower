//
//  MonthlyEnergyReport.swift
//  NowerCore
//
//  월간 에너지 리포트 — MonthDensity(예측 집계) 위에 사용자 체감(DayReflection)을
//  얹어 "이번 달 하루가 어땠나"를 부담·언제·체감으로 읽어준다.
//  추억 아카이브가 아니라 에너지 회고 — 처방 한 줄로 닫는다.
//  순수 함수, 룰 기반(온디바이스). LLM 미사용.
//

import Foundation

/// 체감 밴드 분포 (여유/보통/과부하 일수)
public struct FeltDistribution: Sendable, Equatable {
    public let light: Int
    public let moderate: Int
    public let heavy: Int

    public init(light: Int, moderate: Int, heavy: Int) {
        self.light = light
        self.moderate = moderate
        self.heavy = heavy
    }

    public var total: Int { light + moderate + heavy }
}

/// 한 달 에너지 리포트 (예측 + 체감 종합)
public struct MonthlyEnergyReport: Sendable {
    /// 기준 월(그 달의 어떤 날짜든 무방, 표시용)
    public let month: Date
    /// 예측 기반 월 밀도 집계
    public let density: MonthDensityReport
    /// 사용자 체감 분포 (기록 있는 날만)
    public let felt: FeltDistribution
    /// 예측보다 무겁게 느낀 날 수(체감 > 예측 밴드)
    public let heavierThanExpectedDays: Int
    /// 예측보다 가볍게 느낀 날 수(체감 < 예측 밴드)
    public let lighterThanExpectedDays: Int
    /// 현재 적용 중인 개인 보정값
    public let calibration: DensityCalibration
    /// 월 요약 narration (예측 + 체감)
    public let narration: String
    /// 처방 한 줄 (다음 달을 위한 행동). 없을 수도 있음.
    public let prescription: String?

    public init(
        month: Date,
        density: MonthDensityReport,
        felt: FeltDistribution,
        heavierThanExpectedDays: Int,
        lighterThanExpectedDays: Int,
        calibration: DensityCalibration,
        narration: String,
        prescription: String?
    ) {
        self.month = month
        self.density = density
        self.felt = felt
        self.heavierThanExpectedDays = heavierThanExpectedDays
        self.lighterThanExpectedDays = lighterThanExpectedDays
        self.calibration = calibration
        self.narration = narration
        self.prescription = prescription
    }
}

public enum MonthlyEnergyReportEngine {

    private static let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]

    /// 월 밀도 집계 + 그 달 체감 기록 → 월간 에너지 리포트.
    /// - Parameters:
    ///   - month: 기준 월(표시용)
    ///   - density: MonthDensityEngine.score 결과
    ///   - reflections: 전체 체감 기록(해당 월만 내부에서 추림)
    ///   - calibration: 현재 개인 보정값
    public static func make(
        month: Date,
        density: MonthDensityReport,
        reflections: [DayReflection],
        calibration: DensityCalibration,
        calendar: Calendar = .current
    ) -> MonthlyEnergyReport {
        let comps = calendar.dateComponents([.year, .month], from: month)
        let monthReflections = reflections.filter {
            let c = calendar.dateComponents([.year, .month], from: $0.date)
            return c.year == comps.year && c.month == comps.month
        }

        let felt = FeltDistribution(
            light: monthReflections.filter { $0.feltBand == .light }.count,
            moderate: monthReflections.filter { $0.feltBand == .moderate }.count,
            heavy: monthReflections.filter { $0.feltBand == .heavy }.count
        )
        let heavier = monthReflections.filter { $0.feltGapSteps > 0 }.count
        let lighter = monthReflections.filter { $0.feltGapSteps < 0 }.count

        let narration = buildNarration(
            density: density,
            felt: felt,
            heavier: heavier,
            lighter: lighter,
            calendar: calendar
        )
        let prescription = buildPrescription(
            density: density,
            felt: felt,
            heavier: heavier,
            calendar: calendar
        )

        return MonthlyEnergyReport(
            month: month,
            density: density,
            felt: felt,
            heavierThanExpectedDays: heavier,
            lighterThanExpectedDays: lighter,
            calibration: calibration,
            narration: narration,
            prescription: prescription
        )
    }

    // MARK: - narration

    private static func buildNarration(
        density: MonthDensityReport,
        felt: FeltDistribution,
        heavier: Int,
        lighter: Int,
        calendar: Calendar
    ) -> String {
        let loaded = density.heavyCount + density.moderateCount + density.lightCount
        guard loaded > 0 else {
            return "이번 달은 시간 지정 일정이 거의 없는, 비워둔 달이었어요."
        }

        var parts: [String] = []

        // 부담의 결
        if density.heavyCount > 0 {
            parts.append("빡빡한 날 \(density.heavyCount)일")
        } else {
            parts.append("빡빡한 날 없이 지나간 달")
        }
        if let wd = density.busiestWeekday, wd >= 1, wd <= 7 {
            parts.append("\(weekdayNames[wd - 1])요일이 가장 빡빡했어요")
        }

        var sentence = "이번 달 " + parts.joined(separator: " · ") + "."

        // 체감 결 (기록이 있을 때만)
        if felt.total > 0 {
            if heavier > lighter && heavier > 0 {
                sentence += " 예측보다 더 버겁게 느낀 날이 \(heavier)일 있었어요."
            } else if lighter > heavier && lighter > 0 {
                sentence += " 예측보다 가볍게 넘긴 날이 \(lighter)일이었어요."
            } else {
                sentence += " 체감은 대체로 예측과 비슷했어요."
            }
        }

        return sentence
    }

    // MARK: - 처방

    private static func buildPrescription(
        density: MonthDensityReport,
        felt: FeltDistribution,
        heavier: Int,
        calendar: Calendar
    ) -> String? {
        // 과부하가 특정 요일에 몰렸으면 → 분산 처방
        if density.heavyCount >= 2, let wd = density.busiestWeekday, wd >= 1, wd <= 7 {
            return "다음 달엔 \(weekdayNames[wd - 1])요일에 몰린 일정을 다른 날로 나눠보세요. 같은 양이어도 덜 지쳐요."
        }
        // 체감이 예측보다 계속 무거웠으면 → 회복 처방
        if heavier >= 3 {
            return "예측보다 힘든 날이 잦았어요. 다음 달엔 빈 하루 하나를 미리 비워두면 회복에 도움이 돼요."
        }
        // 여유로운 달 → 긍정 확인(불안 키우지 않음)
        if density.heavyCount == 0 && (density.moderateCount + density.lightCount) > 0 {
            return "잘 흘러간 달이에요. 이 리듬을 다음 달에도 지켜보세요."
        }
        return nil
    }
}
