//
//  EventTimeFormatting.swift
//  NowerCore
//
//  일정 시간 표기/파싱의 단일 출처. iOS·macOS 프레젠테이션이 각자 인라인으로
//  중복 구현하던 "HH:mm ↔ 오전/오후 h:mm" 변환을 한곳으로 모은다. 순수 함수.
//

import Foundation

public enum EventTimeFormatting {

    /// "HH:mm" → ParsedTime (유효한 24시간 시각일 때만).
    public static func parse(hhmm: String) -> ParsedTime? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]),
              h >= 0, h < 24, m >= 0, m < 60 else { return nil }
        return ParsedTime(hour: h, minute: m)
    }

    /// 한국어 12시간 표기 — "오전 9:00", "오후 1:30", "오전 12:00"(자정), "오후 12:00"(정오).
    public static func displayKorean(_ time: ParsedTime) -> String {
        let period = time.hour < 12 ? "오전" : "오후"
        let displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour)
        return String(format: "%@ %d:%02d", period, displayHour, time.minute)
    }

    /// "HH:mm" → 한국어 12시간 표기. 파싱 실패 시 원본 문자열을 그대로 반환.
    public static func displayKorean(hhmm: String) -> String {
        guard let t = parse(hhmm: hhmm) else { return hhmm }
        return displayKorean(t)
    }

    /// 종료 시각이 시작 시각보다 뒤인지(같으면 false). 둘 중 하나라도 없으면 nil.
    public static func isEndAfterStart(startHHmm: String?, endHHmm: String?) -> Bool? {
        guard let s = startHHmm.flatMap(parse(hhmm:)),
              let e = endHHmm.flatMap(parse(hhmm:)) else { return nil }
        return e > s
    }
}
