//
//  EventDraftParser.swift
//  NowerCore
//
//  한국어 자연어 → ParsedEventDraft 변환. 순수 함수 (Foundation only).
//  바로 일정으로 만들지 않고 초안만 반환한다 — 확정은 사용자 몫.
//
//  지원: 상대 날짜(오늘/내일/모레/글피), 요일(이번주/다음주 X요일),
//        시각("3시","오후 3시","15:00","3시 반","3시 30분","1100","930","11am","2pm","정오","자정"),
//        시간 범위("3시부터 5시까지","2시~4시","11:00-13:00","1100~1300"),
//        반복(매일/매주/매주 X요일/매월/매년).
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
        var ambiguousMeridiem = false

        // 1) 반복
        if let (rule, range) = matchRecurrence(in: working, calendar: cal) {
            recurrence = rule
            working.removeSubrange(range)
        }

        // 2) 날짜 (상대 → 요일 순)
        if let (d, cleaned) = matchRelativeDate(in: working, reference: referenceDate, calendar: cal) {
            date = d
            working = cleaned
        } else if let (d, range) = matchWeekday(in: working, reference: referenceDate, calendar: cal) {
            date = d
            working.removeSubrange(range)
        }

        // 3) 시간 (시 범위 → 숫자/콜론 범위 → 단일)
        if let (s, e, range, amb) = matchTimeRange(in: working) {
            start = s; end = e; ambiguousMeridiem = amb
            working.removeSubrange(range)
        } else if let (s, e, range) = matchNumericRange(in: working) {
            start = s; end = e; ambiguousMeridiem = false
            working.removeSubrange(range)
        } else if let (s, range, amb) = matchSingleTime(in: working) {
            start = s; ambiguousMeridiem = amb
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
            confidence: confidence,
            startMeridiemAmbiguous: ambiguousMeridiem
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

    /// 상대 날짜를 찾아 (날짜, 키워드를 모두 제거한 텍스트)를 반환한다.
    /// "내일부터 모레까지"처럼 키워드가 여럿이면 전부 제거(제목 누수 방지)하고,
    /// 가장 먼저 등장한 키워드를 단일 날짜로 채택한다(범위의 시작일 기준).
    /// 긴 키워드(내일모레) 우선 매칭으로 부분 중복(내일/모레)을 막는다.
    private static func matchRelativeDate(in text: String, reference: Date, calendar: Calendar) -> (Date, String)? {
        let keywords: [(String, Int)] = [
            ("내일모레", 2), ("글피", 3), ("모레", 2), ("내일", 1), ("오늘", 0)
        ]
        var working = text
        var picked: (pos: Int, offset: Int)?

        for (word, offset) in keywords {
            while let r = working.range(of: word) {
                let pos = working.distance(from: working.startIndex, to: r.lowerBound)
                if picked == nil || pos < picked!.pos { picked = (pos, offset) }
                // 길이를 보존하는 공백으로 치환 → 남은 위치 비교가 안정적, 하위 키워드 재매칭 방지
                let blanks = String(repeating: " ", count: word.count)
                working.replaceSubrange(r, with: blanks)
            }
        }

        guard let p = picked else { return nil }
        let base = calendar.startOfDay(for: reference)
        let d = calendar.date(byAdding: .day, value: p.offset, to: base) ?? base
        return (d, working)
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

    private static func matchTimeRange(in text: String) -> (ParsedTime, ParsedTime, Range<String.Index>, Bool)? {
        // (period)? H시 (M분|반)? (부터|~|-) (period)? H시 (M분|반)? (까지)?
        let pattern = "(오전|오후|아침|점심|저녁|밤|새벽)?\\s*(\\d{1,2})\\s*시\\s*(\\d{1,2})?\\s*(분|반)?\\s*(?:부터|~|-)\\s*(오전|오후|아침|점심|저녁|밤|새벽)?\\s*(\\d{1,2})\\s*시\\s*(\\d{1,2})?\\s*(분|반)?\\s*(?:까지)?"
        guard let r = firstMatch(text, pattern: pattern) else { return nil }
        let s = makeTime(text, hourGroup: r.groups[2], minGroup: r.groups[3], banGroup: r.groups[4], periodGroup: r.groups[1])
        let e = makeTime(text, hourGroup: r.groups[6], minGroup: r.groups[7], banGroup: r.groups[8], periodGroup: r.groups[5])
        guard let s = s, let e = e else { return nil }
        let ambiguous = isMeridiemAmbiguous(text, hourGroup: r.groups[2], periodGroup: r.groups[1])
        return (s, e, r.full, ambiguous)
    }

    private static func matchSingleTime(in text: String) -> (ParsedTime, Range<String.Index>, Bool)? {
        // 1) HH:mm (+ 선택적 am/pm) — 24시간/명시이므로 모호하지 않음
        if let r = firstMatch(text, pattern: "(\\d{1,2}):(\\d{2})\\s*([aApP][mM])?") {
            let h0 = Int(text[r.groups[1]!]) ?? 0
            let m = Int(text[r.groups[2]!]) ?? 0
            if h0 < 24 && m < 60 {
                let h = r.groups[3].map { applyAmPm(hour: h0, ampm: String(text[$0])) } ?? h0
                return (ParsedTime(hour: h % 24, minute: m), r.full, false)
            }
        }
        // 2) 정오 / 자정
        if let r = firstMatch(text, pattern: "(정오|자정)") {
            let isNoon = String(text[r.groups[1]!]) == "정오"
            return (ParsedTime(hour: isNoon ? 12 : 0, minute: 0), r.full, false)
        }
        // 3) 콜론 없는 영문 am/pm — "11am", "2 pm"
        if let r = firstMatch(text, pattern: "(\\d{1,2})\\s*([aApP][mM])") {
            let h0 = Int(text[r.groups[1]!]) ?? 0
            if h0 >= 1 && h0 <= 12 {
                let h = applyAmPm(hour: h0, ampm: String(text[r.groups[2]!]))
                return (ParsedTime(hour: h % 24, minute: 0), r.full, false)
            }
        }
        // 4) (period)? H시 (M분|반)?
        if let r = firstMatch(text, pattern: "(오전|오후|아침|점심|저녁|밤|새벽)?\\s*(\\d{1,2})\\s*시\\s*(\\d{1,2})?\\s*(분|반)?") {
            if let t = makeTime(text, hourGroup: r.groups[2], minGroup: r.groups[3], banGroup: r.groups[4], periodGroup: r.groups[1]) {
                let ambiguous = isMeridiemAmbiguous(text, hourGroup: r.groups[2], periodGroup: r.groups[1])
                return (t, r.full, ambiguous)
            }
        }
        // 5) 맨숫자 3~4자리 (HHMM / HMM) — "1100"→11:00, "930"→9:30.
        //    오인식 방지: 앞뒤가 공백/문자열 경계인 독립 토큰만.
        if let r = firstMatch(text, pattern: "(?:^|\\s)(\\d{3,4})(?=\\s|$)"),
           let g = r.groups[1], let t = parseBareDigits(String(text[g])) {
            return (t, r.full, false)
        }
        return nil
    }

    /// "HHMM"/"HMM" 맨숫자 → ParsedTime (유효 시각일 때만)
    private static func parseBareDigits(_ s: String) -> ParsedTime? {
        let h: Int, m: Int
        switch s.count {
        case 4: h = Int(s.prefix(2)) ?? -1; m = Int(s.suffix(2)) ?? -1
        case 3: h = Int(s.prefix(1)) ?? -1; m = Int(s.suffix(2)) ?? -1
        default: return nil
        }
        guard h >= 0, h < 24, m >= 0, m < 60 else { return nil }
        return ParsedTime(hour: h, minute: m)
    }

    /// am/pm 보정. 12am→0, 12pm→12, 그 외 pm은 +12.
    private static func applyAmPm(hour: Int, ampm: String) -> Int {
        let isPM = ampm.lowercased().hasPrefix("p")
        if isPM { return hour == 12 ? 12 : hour + 12 }
        return hour == 12 ? 0 : hour
    }

    /// 콜론/맨숫자 시간 범위 — "11:00-13:00", "1100~1300", "9:00부터 18:00까지"
    private static func matchNumericRange(in text: String) -> (ParsedTime, ParsedTime, Range<String.Index>)? {
        let pattern = "(\\d{1,2}:\\d{2}|\\d{3,4})\\s*(?:부터|~|-|–)\\s*(\\d{1,2}:\\d{2}|\\d{3,4})\\s*(?:까지)?"
        guard let r = firstMatch(text, pattern: pattern),
              let s = parseNumericToken(String(text[r.groups[1]!])),
              let e = parseNumericToken(String(text[r.groups[2]!])) else { return nil }
        return (s, e, r.full)
    }

    /// "HH:mm" 또는 맨숫자 토큰 → ParsedTime
    private static func parseNumericToken(_ token: String) -> ParsedTime? {
        if token.contains(":") {
            let parts = token.split(separator: ":")
            guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]),
                  h < 24, m < 60 else { return nil }
            return ParsedTime(hour: h, minute: m)
        }
        return parseBareDigits(token)
    }

    /// 오전/오후 미명시 + 시각이 1~11시라 추정이 들어간 경우 true.
    private static func isMeridiemAmbiguous(_ text: String, hourGroup: Range<String.Index>?, periodGroup: Range<String.Index>?) -> Bool {
        guard periodGroup == nil, let hg = hourGroup, let h = Int(text[hg]) else { return false }
        return (1...11).contains(h)
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
