//
//  TodayWidget.swift
//  Nower-iOS
//
//  Created by AI Assistant on 2026/01/21.
//
//  위젯에서 오늘 일정을 보여주는 WidgetKit 구현입니다.
//  - 데이터 소스: iCloud(NSUbiquitousKeyValueStore)에 저장된 TodoItem
//  - 표시 규칙: 오늘 포함 일정 최대 2개 + 나머지는 “+N개”
//

import WidgetKit
import SwiftUI
import Foundation
import NowerCore

// MARK: - Widget 전용 TodoItem 정의

/// 위젯 전용 Todo 아이템 데이터 모델
/// iOS 앱의 TodoItem과 동일한 구조이지만, 위젯 타겟에만 포함됩니다.
/// UIKit 의존성 없이 순수 Foundation만 사용합니다.
struct WidgetTodoItem: Identifiable, Codable {
    var id = UUID()
    let text: String
    let isRepeating: Bool
    let date: String // yyyy-MM-dd 형식
    let colorName: String
    
    // 기간별 일정을 위한 필드들
    let startDate: String? // yyyy-MM-dd 형식, nil이면 단일 날짜 일정
    let endDate: String?   // yyyy-MM-dd 형식, nil이면 단일 날짜 일정

    /// 시작 시각 "HH:mm" (앱의 TodoItem 데이터에서 함께 읽힘, 없으면 종일)
    var scheduledTime: String? = nil
    
    /// 단일 날짜 WidgetTodoItem 생성자
    init(text: String, isRepeating: Bool, date: String, colorName: String) {
        self.text = text
        self.isRepeating = isRepeating
        self.date = date
        self.colorName = colorName
        self.startDate = nil
        self.endDate = nil
    }
    
    /// Date 객체로부터 단일 날짜 WidgetTodoItem 생성
    init(text: String, isRepeating: Bool, date: Date, colorName: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        self.text = text
        self.isRepeating = isRepeating
        self.date = formatter.string(from: date)
        self.colorName = colorName
        self.startDate = nil
        self.endDate = nil
    }
    
    /// 기간별 WidgetTodoItem 생성자
    init(text: String, isRepeating: Bool, startDate: Date, endDate: Date, colorName: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        self.text = text
        self.isRepeating = isRepeating
        self.date = formatter.string(from: startDate)
        self.colorName = colorName
        self.startDate = formatter.string(from: startDate)
        self.endDate = formatter.string(from: endDate)
    }
    
    /// 기간별 일정인지 확인
    var isPeriodEvent: Bool {
        return startDate != nil && endDate != nil
    }
    
    /// 시작 날짜를 Date 객체로 변환
    var startDateObject: Date? {
        guard let startDate = startDate else { return dateObject }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: startDate)
    }
    
    /// 종료 날짜를 Date 객체로 변환
    var endDateObject: Date? {
        guard let endDate = endDate else { return dateObject }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: endDate)
    }
    
    /// 날짜 문자열을 Date 객체로 변환
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    /// 특정 날짜가 이 일정의 기간에 포함되는지 확인
    func includesDate(_ date: Date) -> Bool {
        // 위젯에서 안정적인 날짜 파싱을 위해 로케일 설정
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX") // 위젯에서 안정적인 파싱을 위해
        let dateString = formatter.string(from: date)
        
        if isPeriodEvent {
            guard let start = startDate, let end = endDate else {
                return false
            }
            // 문자열 비교로 날짜 범위 확인
            let isIncluded = dateString >= start && dateString <= end
            if isIncluded {
            }
            return isIncluded
        } else {
            let isIncluded = self.date == dateString
            if isIncluded {
            }
            return isIncluded
        }
    }
}

// MARK: - Widget 전용 색상 정의 (SwiftUI Color 기반)

/// 위젯에서 사용하는 SwiftUI Color 기반 색상 정의
/// iOS 앱의 `AppColors`(UIColor+Extension.swift)와 동일한 팔레트를 사용합니다.
/// - HIG / WCAG 기준을 맞추기 위해 같은 RGB 값을 그대로 사용합니다.
enum WidgetAppColors {
    // MARK: 텍스트 색상
    /// 기본 텍스트 색상 (AppColors.textPrimary)
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #F5F5F7
            return Color(red: 0.96, green: 0.96, blue: 0.97)
        } else {
            // #0F0F0F
            return Color(red: 0.06, green: 0.06, blue: 0.06)
        }
    }
    
    /// 플레이스홀더 텍스트 색상 (AppColors.textFieldPlaceholder)
    static func textFieldPlaceholder(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #8E8E93
            return Color(red: 0.56, green: 0.56, blue: 0.58)
        } else {
            // #D4D4D4
            return Color(red: 0.83, green: 0.83, blue: 0.84)
        }
    }
    
    // MARK: 배경 색상
    /// 위젯 내부 카드 배경 (AppColors.popupBackground와 동일)
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #1C1C1E
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        } else {
            // #FFFFFF
            return Color.white
        }
    }
    
    /// 캡슐/카드 배경 (AppColors.todoBackground와 유사)
    static func todoBackground(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #2C2C2E
            return Color(red: 0.17, green: 0.17, blue: 0.18)
        } else {
            // #F2F2F7
            return Color(red: 0.95, green: 0.95, blue: 0.97)
        }
    }
    
    // MARK: 강조 색상
    /// 오늘 날짜 하이라이트 색상 (AppColors.textHighlighted)
    static func textHighlighted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 1.0, green: 0.60, blue: 0.52) : Color(red: 1.0, green: 0.49, blue: 0.38)
    }

    // MARK: 테마 색상 (일정 색상)
    /// skyblue (AppColors.skyblue)
    static func skyblue(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #59A0CC
            return Color(red: 0.35, green: 0.60, blue: 0.80)
        } else {
            // #73B3D9
            return Color(red: 0.45, green: 0.70, blue: 0.85)
        }
    }
    
    /// peach (AppColors.peach)
    static func peach(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #F2A673
            return Color(red: 0.95, green: 0.65, blue: 0.45)
        } else {
            // #F2BF8C
            return Color(red: 0.95, green: 0.75, blue: 0.55)
        }
    }
    
    /// lavender (AppColors.lavender)
    static func lavender(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #A68CCC
            return Color(red: 0.65, green: 0.55, blue: 0.80)
        } else {
            // #B399D9
            return Color(red: 0.70, green: 0.60, blue: 0.85)
        }
    }
    
    /// mintgreen (AppColors.mintgreen)
    static func mintgreen(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #4DA68C
            return Color(red: 0.30, green: 0.65, blue: 0.55)
        } else {
            // #66B399
            return Color(red: 0.40, green: 0.70, blue: 0.60)
        }
    }
    
    /// coralred (AppColors.coralred)
    static func coralred(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            // #F28073
            return Color(red: 0.95, green: 0.50, blue: 0.45)
        } else {
            // #F28C80
            return Color(red: 0.95, green: 0.55, blue: 0.50)
        }
    }
    
    /// 기본 색상 이름으로 기본 색상 가져오기 (톤 없음)
    static func baseColor(for name: String, scheme: ColorScheme) -> Color {
        switch name {
        case "skyblue": return skyblue(scheme)
        case "peach": return peach(scheme)
        case "lavender": return lavender(scheme)
        case "mintgreen": return mintgreen(scheme)
        case "coralred": return coralred(scheme)
        default:
            return scheme == .dark ? Color.gray.opacity(0.8) : Color.gray
        }
    }

    /// 색상 톤 생성 (1: 가장 밝음, 8: 가장 어두움)
    /// iOS 앱의 AppColors.colorTone과 동일한 로직
    private static func colorTone(r: CGFloat, g: CGFloat, b: CGFloat, tone: Int, isDark: Bool) -> Color {
        let toneFactor: CGFloat
        if isDark {
            toneFactor = 0.95 - (CGFloat(tone - 1) / 7.0) * 0.65
        } else {
            toneFactor = 0.95 - (CGFloat(tone - 1) / 7.0) * 0.55
        }

        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        guard luminance > 0 else { return Color(red: r, green: g, blue: b) }

        let ratio = toneFactor / luminance
        let nr = min(1.0, max(0.0, r * ratio))
        let ng = min(1.0, max(0.0, g * ratio))
        let nb = min(1.0, max(0.0, b * ratio))
        return Color(red: nr, green: ng, blue: nb)
    }

    /// 기본 색상의 RGB 값 반환
    private static func baseColorRGB(for name: String, scheme: ColorScheme) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let isDark = scheme == .dark
        switch name {
        case "skyblue":   return isDark ? (0.35, 0.60, 0.80) : (0.45, 0.70, 0.85)
        case "peach":     return isDark ? (0.95, 0.65, 0.45) : (0.95, 0.75, 0.55)
        case "lavender":  return isDark ? (0.65, 0.55, 0.80) : (0.70, 0.60, 0.85)
        case "mintgreen": return isDark ? (0.30, 0.65, 0.55) : (0.40, 0.70, 0.60)
        case "coralred":  return isDark ? (0.95, 0.50, 0.45) : (0.95, 0.55, 0.50)
        default:          return isDark ? (0.50, 0.50, 0.50) : (0.50, 0.50, 0.50)
        }
    }

    /// 테마 색상 이름으로 색상 가져오기 (톤 지원)
    /// 지원 형식: "skyblue", "skyblue-1" ~ "skyblue-8"
    static func color(for name: String, scheme: ColorScheme) -> Color {
        // 톤이 포함된 경우 (예: "skyblue-3")
        if let dashIndex = name.lastIndex(of: "-"),
           let tone = Int(String(name[name.index(after: dashIndex)...])),
           tone >= 1 && tone <= 8 {
            let baseName = String(name[..<dashIndex])
            let rgb = baseColorRGB(for: baseName, scheme: scheme)
            return colorTone(r: rgb.r, g: rgb.g, b: rgb.b, tone: tone, isDark: scheme == .dark)
        }

        // 톤 없는 기본 색상 → 중간 톤(4) 적용
        let rgb = baseColorRGB(for: name, scheme: scheme)
        return colorTone(r: rgb.r, g: rgb.g, b: rgb.b, tone: 4, isDark: scheme == .dark)
    }

    /// 테마 색상에 대비되는 텍스트 색상 (WCAG 기반)
    static func capsuleTextColor(_ scheme: ColorScheme) -> Color {
        return Color.white
    }
}

// MARK: - Entry

struct TodayEntry: TimelineEntry {
    let date: Date
    let todos: [WidgetTodoItem] // 위젯 전용 TodoItem 사용
}

// MARK: - TimelineProvider

struct TodayProvider: TimelineProvider {

    // placeholder에서는 더미 데이터 사용
    func placeholder(in context: Context) -> TodayEntry {
        // 위젯 미리보기용 더미 데이터
        let sample1 = WidgetTodoItem(text: "샘플 일정 1", isRepeating: false, date: Date(), colorName: "skyblue")
        let sample2 = WidgetTodoItem(text: "샘플 일정 2", isRepeating: false, date: Date(), colorName: "coralred")
        return TodayEntry(date: Date(), todos: [sample1, sample2])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        let entry = loadTodayEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date()
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let todos = loadTodayEntry().todos

        // 오늘 시간 일정의 경계(시작/끝)를 모아 각 시점마다 엔트리를 만든다.
        // → 일정이 시작/끝나는 바로 그 순간 위젯이 다음 일정으로 자동 전환된다.
        //   (시스템 reload 예산에 의존하지 않음)
        var boundaries = Set<Date>()
        for todo in todos {
            guard let t = todo.scheduledTime, let start = WidgetTodayInsight.combine(t, today) else { continue }
            if start > now { boundaries.insert(start) }
            let end = start.addingTimeInterval(3600) // 인사이트와 동일한 1시간 길이 가정
            if end > now { boundaries.insert(end) }
        }

        // 현재 시점 + 미래 경계들을 엔트리로. View가 entry.date를 'now'로 써서 다음 일정을 다시 계산.
        let dates = ([now] + boundaries.sorted()).prefix(60)
        let entries = dates.map { TodayEntry(date: $0, todos: todos) }

        // 자정에 새 날짜로 다시 로드
        let reload = cal.date(byAdding: .day, value: 1, to: today) ?? now.addingTimeInterval(86_400)
        completion(Timeline(entries: Array(entries), policy: .after(reload)))
    }

    /// iCloud에 저장된 Todo들 중 오늘 포함 일정을 읽어와 Entry 생성
    private func loadTodayEntry() -> TodayEntry {
        let today = Date()
        
        // 오늘 날짜를 문자열로 변환 (디버깅용)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let todayString = formatter.string(from: today)
        
        // 안전하게 iCloud 데이터 로드
        let allTodos: [WidgetTodoItem]
        do {
            allTodos = try loadTodosFromICloud()
            
            // 디버깅: 모든 일정의 날짜 출력
            for (index, todo) in allTodos.enumerated() {
            }
        } catch {
            // 에러 발생 시 빈 배열 반환
            return TodayEntry(date: today, todos: [])
        }

        // 오늘을 포함하는 일정 필터 (기간 일정 포함)
        let todayTodos = allTodos.filter { todo in
            let includes = todo.includesDate(today)
            if includes {
            }
            return includes
        }
        

        return TodayEntry(date: today, todos: todayTodos)
    }

    /// CloudSyncManager와 동일한 키/포맷으로 NSUbiquitousKeyValueStore에서 Todo 목록 로딩
    /// - Throws: 디코딩 오류 시 에러를 던짐
    private func loadTodosFromICloud() throws -> [WidgetTodoItem] {
        let store = NSUbiquitousKeyValueStore.default
        let todosKey = "SavedTodos"
        
        // iCloud 동기화 강제 실행
        store.synchronize()
        
        // 디버깅: iCloud store의 모든 키 확인
        let allKeys = store.dictionaryRepresentation.keys
        
        // iCloud 접근 권한 확인
        guard let data = store.data(forKey: todosKey) else {
            // 데이터가 없으면 빈 배열 반환 (에러 아님)
            return []
        }
        

        // iOS 앱의 TodoItem과 동일한 구조이므로 JSON 디코딩 가능
        // 위젯에서는 WidgetTodoItem으로 디코딩
        let todos = try JSONDecoder().decode([WidgetTodoItem].self, from: data)
        return todos
    }
}

// MARK: - Companion Insight

/// 위젯용 하루 인사이트 — 밀도 밴드(앱과 동일 엔진)·다음 일정·짧은 문구.
struct WidgetTodayInsight {
    let bandLabel: String
    let bandHex: String
    let nextTime: String?
    let nextTitle: String?
    let phrase: String
    let count: Int

    init(todos: [WidgetTodoItem], now: Date) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let todays = todos.filter { $0.includesDate(today) }
        count = todays.count

        // 앱과 같은 밀도 엔진 사용 (의미 일치)
        var events: [NowerCore.Event] = []
        for t in todays {
            if let timeStr = t.scheduledTime, let start = Self.combine(timeStr, today) {
                events.append(NowerCore.Event(
                    title: t.text, startDateTime: start,
                    endDateTime: start.addingTimeInterval(3600), isAllDay: false))
            } else {
                events.append(NowerCore.Event(
                    title: t.text, startDateTime: today,
                    endDateTime: today.addingTimeInterval(86_399), isAllDay: true))
            }
        }
        let report = DensityEngine.score(DensityInput(day: today, events: events))
        bandLabel = report.band.label
        bandHex = report.band.colorHex

        // 다음 시간 일정
        let upcoming = todays.compactMap { t -> (Date, WidgetTodoItem)? in
            guard let s = t.scheduledTime, let d = Self.combine(s, today), d > now else { return nil }
            return (d, t)
        }.min { $0.0 < $1.0 }
        nextTime = upcoming?.1.scheduledTime
        nextTitle = upcoming?.1.text

        switch report.band {
        case .light:
            phrase = (report.metrics.eventCount == 0 && report.metrics.allDayCount == 0)
                ? "비어 있는 하루예요" : "여유로운 하루예요"
        case .moderate: phrase = "적당히 채워진 하루예요"
        case .heavy: phrase = "촘촘한 하루예요"
        }
    }

    var color: Color { Color(densityHex: bandHex) }

    /// 다음 일정 한 줄 ("15:00 병원") — 없으면 nil
    var nextLine: String? {
        guard let t = nextTime, let title = nextTitle else { return nil }
        return "\(t) \(title)"
    }

    static func combine(_ hhmm: String, _ day: Date) -> Date? {
        let p = hhmm.split(separator: ":")
        guard p.count == 2, let h = Int(p[0]), let m = Int(p[1]) else { return nil }
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: day)
    }
}

// MARK: - View

struct TodayWidgetEntryView: View {
    let entry: TodayEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    private var insight: WidgetTodayInsight {
        WidgetTodayInsight(todos: entry.todos, now: entry.date)
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium: mediumBody
            default: smallBody
            }
        }
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color.black : Color.white
        }
    }

    // systemSmall — 오늘 / 밴드 / 다음 일정. 조용하게.
    private var smallBody: some View {
        let i = insight
        return VStack(alignment: .leading, spacing: 0) {
            Text("오늘")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))

            Spacer(minLength: 6)

            HStack(spacing: 7) {
                Circle().fill(i.color).frame(width: 9, height: 9)
                Text(i.bandLabel)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(WidgetAppColors.textPrimary(colorScheme))
            }
            Text(i.phrase)
                .font(.system(size: 11))
                .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                .lineLimit(1)

            Spacer(minLength: 6)

            if let next = i.nextLine {
                Text("다음 · \(next)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(WidgetAppColors.textPrimary(colorScheme))
                    .lineLimit(1)
            } else {
                Text("남은 일정 없음")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .accessibilityLabel("오늘 밀도 \(i.bandLabel). \(i.nextLine.map { "다음 일정 " + $0 } ?? "남은 일정 없음")")
    }

    // systemMedium — 좌: 밀도 / 우: 다음 일정
    private var mediumBody: some View {
        let i = insight
        return HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                HStack(spacing: 7) {
                    Circle().fill(i.color).frame(width: 10, height: 10)
                    Text(i.bandLabel)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(WidgetAppColors.textPrimary(colorScheme))
                }
                Text(i.phrase)
                    .font(.system(size: 12))
                    .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text("오늘 일정 \(i.count)개")
                    .font(.system(size: 11))
                    .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("다음 일정")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                if let time = i.nextTime, let title = i.nextTitle {
                    Text(time)
                        .font(.system(size: 22, weight: .bold).monospacedDigit())
                        .foregroundColor(i.color)
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WidgetAppColors.textPrimary(colorScheme))
                        .lineLimit(2)
                } else {
                    Text("남은 일정이 없어요")
                        .font(.system(size: 13))
                        .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .accessibilityLabel("오늘 밀도 \(i.bandLabel), 일정 \(i.count)개. \(i.nextLine.map { "다음 일정 " + $0 } ?? "남은 일정 없음")")
    }
}

/// 위젯에서 사용하는 캡슐형 일정 행
private struct CapsuleRow: View {
    let todo: WidgetTodoItem
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        WidgetAppColors.color(for: todo.colorName, scheme: colorScheme)
    }

    private var textColor: Color {
        WidgetAppColors.capsuleTextColor(colorScheme)
    }

    var body: some View {
        HStack(spacing: 6) { // spacing을 8에서 6으로 줄여서 텍스트를 좌측으로 더 당김
            Circle()
                .fill(backgroundColor)
                .frame(width: 6, height: 6)

            Text(todo.text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textColor)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .padding(.leading, 8) // 좌측 패딩을 줄여서 텍스트를 더 앞으로
        .padding(.trailing, 10) // 우측 패딩은 적당히 유지
        .padding(.vertical, 8)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Widget View Router

/// 위젯 패밀리에 따라 적절한 뷰를 표시하는 라우터
struct WidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        default:
            TodayWidgetEntryView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widget Views

/// 잠금화면 원형 위젯 뷰 (일정 개수 표시)
struct LockScreenCircularView: View {
    let entry: TodayEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Text("\(entry.todos.count)")
                    .font(.system(size: 20, weight: .bold))

                Text("일정")
                    .font(.system(size: 9, weight: .medium))
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

/// 잠금화면 사각형 — "오늘 {밴드}" + "다음 일정 15:00 병원"
struct LockScreenRectangularView: View {
    let entry: TodayEntry

    var body: some View {
        let i = WidgetTodayInsight(todos: entry.todos, now: entry.date)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Circle().fill(.primary).frame(width: 6, height: 6)
                Text("오늘 \(i.bandLabel)")
                    .font(.system(size: 14, weight: .semibold))
            }
            if let next = i.nextLine {
                Text("다음 일정 \(next)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text(i.phrase)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .accessibilityLabel("오늘 밀도 \(i.bandLabel). \(i.nextLine.map { "다음 일정 " + $0 } ?? i.phrase)")
    }
}

/// 잠금화면 인라인 — "오늘 2개 · 여유"
struct LockScreenInlineView: View {
    let entry: TodayEntry

    var body: some View {
        let i = WidgetTodayInsight(todos: entry.todos, now: entry.date)
        return Label("오늘 \(i.count)개 · \(i.bandLabel)", systemImage: "circle.fill")
    }
}

// MARK: - Widget

struct NowerTodayWidget: Widget {
    let kind: String = "NowerTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("오늘의 리듬")
        .description("오늘의 밀도와 다음 일정을 조용히 보여줍니다.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

struct TodayWidget_Previews: PreviewProvider {
    static var previews: some View {
        TodayWidgetEntryView(
            entry: TodayEntry(
                date: Date(),
                todos: [
                    WidgetTodoItem(text: "회의 준비", isRepeating: false, date: Date(), colorName: "skyblue"),
                    WidgetTodoItem(text: "헬스장 가기", isRepeating: false, date: Date(), colorName: "coralred")
                ]
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

