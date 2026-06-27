//
//  ReflectionCallback.swift
//  NowerCore
//
//  체감 콜백 — "지난번 이런 날, 버거웠다고 하셨죠."
//  과거에 '이런 날'(같은 예측 밴드)을 과부하로 체감한 기록이 있으면 그걸 짚어,
//  서비스가 "나를 알아간다"는 관계감을 만든다.
//  순수 함수·온디바이스. "근거 없는 말 안 함" — 실제 체감 기록 있을 때만.
//

import Foundation

public enum ReflectionCallbackEngine {

    /// 콜백을 보는 창(일)
    public static let windowDays = 120

    /// 오늘 예측 밴드 + 과거 체감 기록 → 콜백 문구(없으면 nil).
    /// 발화 조건: 오늘이 보통/과부하 예측이고, 같은 예측 밴드였던 과거 날을
    /// '과부하'로 체감한 기록이 1건 이상.
    public static func callback(
        todayBand: DensityBand,
        reflections: [DayReflection],
        asOf: Date,
        calendar: Calendar = .current
    ) -> String? {
        // 여유로운 날엔 경고하지 않는다(불안 키우지 않음)
        guard todayBand != .light else { return nil }
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: asOf) else { return nil }
        let today0 = calendar.startOfDay(for: asOf)

        let matches = reflections.filter {
            let d = calendar.startOfDay(for: $0.date)
            return d >= calendar.startOfDay(for: windowStart)
                && d < today0
                && $0.predictedBand == todayBand
                && $0.feltBand == .heavy
        }
        guard !matches.isEmpty else { return nil }

        if matches.count == 1 {
            return "지난번 이런 날, 좀 버거웠다고 하셨어요. 오늘은 한 칸 비워둘 수 있을까요?"
        }
        return "이런 날 보통 버거워하셨어요 (최근 \(matches.count)번). 미리 한 칸 비워두면 한결 나아요."
    }
}
