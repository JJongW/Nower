//
//  EventDraftParser.swift
//  NowerCore
//
//  한국어 자연어 → ParsedEventDraft 변환. 순수 함수 (Foundation only).
//  바로 일정으로 만들지 않고 초안만 반환한다 — 확정은 사용자 몫.
//
//  지원: 상대 날짜(오늘/내일/모레/글피), 요일(이번주/다음주 X요일),
//        시각("3시","오후 3시","15:00","3시 반","3시 30분"),
//        시간 범위("3시부터 5시까지","2시~4시"), 반복(매일/매주/매주 X요일/매월/매년).
//

import Foundation

public enum EventDraftParser {

    /// 자연어 문자열을 초안으로 파싱한다.
    /// - Parameters:
    ///   - text: 입력 문자열
    ///   - referenceDate: "오늘" 기준 (테스트 결정성 위해 주입)
    ///   - calendar: 사용할 캘린더
    public static func parse(
        _ text: String,
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> ParsedEventDraft {
        var working = text
        var cal = calendar
        cal.timeZone = calendar.timeZone

        var date: Date?
        var recurrence: RecurrenceRule?
        var start: ParsedTime?
        var end: ParsedTime?

        // 1) 반복
        if let (rule, range) = matchRecurrence(in: working, calendar: cal) {
            recurrence = rule
            working.removeSubrange(range)
        }

        // 2) 날짜 (상대 → 요일 순)
        if let (d, range) = matchRelativeDate(in: working, reference: referenceDate, calendar: cal) {
            date = d
            working.removeSubrange(range)
        } else if let (d, range) = matchWeekday(in: working, reference: referenceDate, calendar: cal) {
            date = d
            working.removeSubrange(range)
        }

        // 3) 시간 (범위 우선 → 단일)
        if let (s, e, range) = matchTimeRange(in: working) {
            start = s; end = e
            working.removeSubrange(range)
        } else if let (s, range) = matchSingleTime(in: working) {
            start = s
            working.removeSubrange(range)
        }

        // 4) 제목 정리
        let title = cleanupTitle(working)

        // 5) 종일/확신도
        let isAllDay = (start == nil)
        let confidence = confidenceOf(date: date, start: start, recurrence: recurrence, title: title)

        return ParsedEventDraft(
            title: title,
            date: date,
            startTime: start,
            endTime: end,
            isAllDay: isAllDay,
            recurrenceRule: recurrence,
            confidence: confidence
        )
    }

    // MARK: - 반복

    private static let weekdayChars: [Character: Int] = [
        "일": 1, "월": 2, "화": 3, "수": 4, "목": 5, "금": 6, "토": 7
    ]

    private static func matchRecurrence(in text: String, calendar: Calendar) -> (RecurrenceRule, Range<String.Index>)? {
        // 매주 X요일
        if let r = firstMatch(text, pattern: "매주\\s*([월화수목금토일])요일") {
            let dayChar = text[r.groups[1]!].first!
            let wd = weekdayChars[dayChar]!
            return (RecurrenceRule(frequency: .weekly, interval: 1, daysOfWeek: [wd]), r.full)
        }
        // 매일/매주/매월/매년
        if let r = firstMatch(text, pattern: "(매일|매주|매월|매년)") {
            let word = String(text[r.groups[1]!])
            let freq: RecurrenceRule.Frequency
            switch word {
            case "매일": freq = .daily
            case "매주": freq = .weekly
            case "매월": freq = .monthly
            default: freq = .yearly
            }
            return (RecurrenceRule(frequency: freq, interval: 1), r.full)
        }
        return nil
    }

    // MARK: - 상대 날짜

    private static func matchRelativeDate(in text: String, reference: Date, calendar: Calendar) -> (Date, Range<String.Index>)? {
        let map: [(String, Int)] = [
            ("내일모레", 2), ("모레", 2), ("글피", 3), ("내일", 1), ("오늘", 0)
        ]
        for (word, offset) in map {
            if let range = text.range(of: word) {
                let base = calendar.startOfDay(for: reference)
                let d = calendar.date(byAdding: .day, value: offset, to: base) ?? base
                return (d, range)
            }
        }
        return nil
    }

    // MARK: - 요일

    private static func matchWeekday(in text: String, reference: Date, calendar: Calendar) -> (Date, Range<String.Index>)? {
        guard let r = firstMatch(text, pattern: "(다음주|담주|이번주|다음|이번)?\\s*([월화수목금토일])요일") else { return nil }
        let prefix = r.groups[1].map { String(text[$0]) }
        let dayChar = text[r.groups[2]!].first!
        guard let targetWeekday = weekdayChars[dayChar] else { return nil }

        let base = calendar.startOfDay(for: reference)
        let currentWeekday = calendar.component(.weekday, from: base)
        var add = (targetWeekday - currentWeekday + 7) % 7

        switch prefix {
        case "다음주", "담주", "다음":
            add += 7 // 다음 주기로
            if add == 7 && (prefix == "다음주" || prefix == "담주") {
                // 같은 요일이면 7일 뒤가 다음주
            }
        case "이번주", "이번":
            // 이번 주 해당 요일 (지났어도 이번 주 기준 그대로)
            break
        default:
            if add == 0 { add = 7 } // 오늘과 같은 요일이면 다음 주
        }
        let d = calendar.date(byAdding: .day, value: add, to: base) ?? base
        return (d, r.full)
    }

    // MARK: - 시간

    private static func matchTimeRange(in text: String) -> (ParsedTime, ParsedTime, Range<String.Index>)? {
        // (period)? H시 (M분|반)? (부터|~|-) (period)? H시 (M분|반)? (까지)?
        let pattern = "(오전|오후|아침|점심|저녁|밤|새벽)?\\s*(\\d{1,2})\\s*시\\s*(\\d{1,2})?\\s*(분|반)?\\s*(?:부터|~|-)\\s*(오전|오후|아침|점심|저녁|밤|새벽)?\\s*(\\d{1,2})\\s*시\\s*(\\d{1,2})?\\s*(분|반)?\\s*(?:까지)?"
        guard let r = firstMatch(text, pattern: pattern) else { return nil }
        let s = makeTime(text, hourGroup: r.groups[2], minGroup: r.groups[3], banGroup: r.groups[4], periodGroup: r.groups[1])
        let e = makeTime(text, hourGroup: r.groups[6], minGroup: r.groups[7], banGroup: r.groups[8], periodGroup: r.groups[5])
        guard let s = s, let e = e else { return nil }
        return (s, e, r.full)
    }

    private static func matchSingleTime(in text: String) -> (ParsedTime, Range<String.Index>)? {
        // HH:mm
        if let r = firstMatch(text, pattern: "(\\d{1,2}):(\\d{2})") {
            let h = Int(text[r.groups[1]!]) ?? 0
            let m = Int(text[r.groups[2]!]) ?? 0
            if h < 24 && m < 60 { return (ParsedTime(hour: h, minute: m), r.full) }
        }
        // (period)? H시 (M분|반)?
        if let r = firstMatch(text, pattern: "(오전|오후|아침|점심|저녁|밤|새벽)?\\s*(\\d{1,2})\\s*시\\s*(\\d{1,2})?\\s*(분|반)?") {
            if let t = makeTime(text, hourGroup: r.groups[2], minGroup: r.groups[3], banGroup: r.groups[4], periodGroup: r.groups[1]) {
                return (t, r.full)
            }
        }
        return nil
    }

    private static func makeTime(
        _ text: String,
        hourGroup: Range<String.Index>?,
        minGroup: Range<String.Index>?,
        banGroup: Range<String.Index>?,
        periodGroup: Range<String.Index>?
    ) -> ParsedTime? {
        guard let hg = hourGroup, var hour = Int(text[hg]) else { return nil }
        var minute = 0
        if let mg = minGroup, let m = Int(text[mg]) { minute = m }
        if let bg = banGroup, text[bg] == "반" { minute = 30 }
        guard hour >= 0, hour <= 24, minute >= 0, minute < 60 else { return nil }

        let period = periodGroup.map { String(text[$0]) }
        hour = applyMeridiem(hour: hour, period: period)
        return ParsedTime(hour: hour % 24, minute: minute)
    }

    /// 오전/오후 보정 + 맨숫자 휴리스틱
    private static func applyMeridiem(hour: Int, period: String?) -> Int {
        switch period {
        case "오전", "아침", "새벽":
            return hour == 12 ? 0 : hour
        case "오후", "저녁", "밤", "점심":
            return hour < 12 ? hour + 12 : hour
        default:
            // 표기 없음: 1~6시는 오후로 추정(오후 1~6시가 흔함), 7~11시는 오전 그대로, 그 외 24시간
            // (예: "3시"→15시, "9시"→9시, "7시"→7시)
            if hour >= 1 && hour <= 6 { return hour + 12 }
            return hour
        }
    }

    // MARK: - 제목 정리

    private static func cleanupTitle(_ text: String) -> String {
        var t = text
        // 시간/날짜 조사 잔여 제거
        for token in ["에서", "에", "쯤", "때", "부터", "까지", "~", "-"] {
            t = t.replacingOccurrences(of: token, with: " ")
        }
        // 공백 정리
        let parts = t.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 확신도

    private static func confidenceOf(date: Date?, start: ParsedTime?, recurrence: RecurrenceRule?, title: String) -> ParseConfidence {
        let hasDate = date != nil || recurrence != nil
        if hasDate && start != nil { return .high }
        if hasDate || start != nil { return .medium }
        return .low
    }

    // MARK: - 정규식 헬퍼

    private struct RegexMatch {
        let full: Range<String.Index>
        let groups: [Range<String.Index>?] // [0]=전체, [1..]=캡처
    }

    private static func firstMatch(_ text: String, pattern: String) -> RegexMatch? {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        guard let m = re.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        guard let full = Range(m.range, in: text) else { return nil }
        var groups: [Range<String.Index>?] = []
        for i in 0..<m.numberOfRanges {
            groups.append(Range(m.range(at: i), in: text))
        }
        return RegexMatch(full: full, groups: groups)
    }
}
