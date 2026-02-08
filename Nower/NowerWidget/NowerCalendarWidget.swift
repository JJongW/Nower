//
//  NowerCalendarWidget.swift
//  NowerWidgetExtension
//
//  Created by AI Assistant on 2026/01/22.
//
//  macOS 전용 월 달력 위젯
//  - 각 날짜 셀 안에 일정을 직접 표시
//  - 네이버 캘린더 위젯처럼 모든 일정이 보이도록 구현

import WidgetKit
import SwiftUI
import Foundation

// MARK: - Widget Todo Item

struct WidgetTodoItem: Identifiable, Codable {
    var id = UUID()
    var text: String
    var isRepeating: Bool
    var date: String // yyyy-MM-dd 형식
    var colorName: String
    var startDate: String?
    var endDate: String?
    
    init(text: String, isRepeating: Bool, date: String, colorName: String) {
        self.id = UUID()
        self.text = text
        self.isRepeating = isRepeating
        self.date = date
        self.colorName = colorName
        self.startDate = nil
        self.endDate = nil
    }
    
    init(text: String, isRepeating: Bool, date: Date, colorName: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        self.id = UUID()
        self.text = text
        self.isRepeating = isRepeating
        self.date = formatter.string(from: date)
        self.colorName = colorName
        self.startDate = nil
        self.endDate = nil
    }
    
    init(text: String, isRepeating: Bool, startDate: Date, endDate: Date, colorName: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        self.id = UUID()
        self.text = text
        self.isRepeating = isRepeating
        self.date = formatter.string(from: startDate)
        self.colorName = colorName
        self.startDate = formatter.string(from: startDate)
        self.endDate = formatter.string(from: endDate)
    }
    
    var isPeriodEvent: Bool {
        return startDate != nil && endDate != nil
    }
    
    func includesDate(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: date)
        
        if isPeriodEvent {
            guard let start = startDate, let end = endDate else { return false }
            return dateString >= start && dateString <= end
        } else {
            return self.date == dateString
        }
    }
}

// MARK: - Calendar Day Info

struct CalendarDayInfo {
    let day: Int?
    let dateString: String
    let isToday: Bool
    let isSunday: Bool
    let isSaturday: Bool
    let holidayName: String?
    let todos: [WidgetTodoItem]
}

// MARK: - Calendar Entry

struct CalendarEntry: TimelineEntry {
    let date: Date
    let currentMonth: Date
    let weeks: [[CalendarDayInfo]]
    let allTodos: [WidgetTodoItem]
    let periodEvents: [WidgetTodoItem]
    let singleDayEvents: [WidgetTodoItem]
}

// MARK: - Widget App Colors

enum WidgetAppColors {
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.96, green: 0.96, blue: 0.97) : Color(red: 0.06, green: 0.06, blue: 0.06)
    }
    
    static func textFieldPlaceholder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.56, green: 0.56, blue: 0.58) : Color(red: 0.83, green: 0.83, blue: 0.84)
    }
    
    static func textHighlighted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 1.0, green: 0.60, blue: 0.52) : Color(red: 1.0, green: 0.49, blue: 0.38)
    }
    
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }
    
    static func skyblue(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.35, green: 0.60, blue: 0.80) : Color(red: 0.45, green: 0.70, blue: 0.85)
    }
    
    static func peach(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.95, green: 0.65, blue: 0.45) : Color(red: 0.95, green: 0.75, blue: 0.55)
    }
    
    static func lavender(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.65, green: 0.55, blue: 0.80) : Color(red: 0.70, green: 0.60, blue: 0.85)
    }
    
    static func mintgreen(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.30, green: 0.65, blue: 0.55) : Color(red: 0.40, green: 0.70, blue: 0.60)
    }
    
    static func coralred(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.95, green: 0.50, blue: 0.45) : Color(red: 0.95, green: 0.55, blue: 0.50)
    }
    
    /// 기본 색상 이름으로 기본 색상 가져오기 (톤 없음)
    static func baseColor(for name: String, scheme: ColorScheme) -> Color {
        switch name {
        case "skyblue": return skyblue(scheme)
        case "peach": return peach(scheme)
        case "lavender": return lavender(scheme)
        case "mintgreen": return mintgreen(scheme)
        case "coralred": return coralred(scheme)
        default: return scheme == .dark ? Color.gray.opacity(0.8) : Color.gray
        }
    }

    /// 색상 톤 생성 (1: 가장 밝음, 8: 가장 어두움)
    /// macOS 앱의 AppColors.colorTone과 동일한 로직
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
}

// MARK: - Calendar Provider

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        let today = Date()
        let calendar = Calendar.current
        let month = calendar.dateInterval(of: .month, for: today)?.start ?? today
        
        // 실제 캘린더 데이터 생성
        return generateCalendarEntry(for: month, todos: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let today = Date()
        let calendar = Calendar.current
        let month = calendar.dateInterval(of: .month, for: today)?.start ?? today
        
        // iCloud에서 일정 로드 (안전하게)
        let todos = loadTodosFromICloud()
        let entry = generateCalendarEntry(for: month, todos: todos)
        
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    func generateCalendarEntry(for month: Date, todos: [WidgetTodoItem]) -> CalendarEntry {
        let calendar = Calendar.current
        let today = Date()
        
        guard let firstDay = calendar.dateInterval(of: .month, for: month)?.start else {
            return CalendarEntry(date: today, currentMonth: month, weeks: [], allTodos: todos, periodEvents: [], singleDayEvents: [])
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysToSubtract = (firstWeekday - 1) % 7
        guard let firstSunday = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDay) else {
            return CalendarEntry(date: today, currentMonth: month, weeks: [], allTodos: todos, periodEvents: [], singleDayEvents: [])
        }
        
        var weeks: [[CalendarDayInfo]] = []
        var currentDate = firstSunday
        
        for _ in 0..<6 {
            var week: [CalendarDayInfo] = []
            
            for _ in 0..<7 {
                let isInMonth = calendar.isDate(currentDate, equalTo: month, toGranularity: .month)
                let day = isInMonth ? calendar.component(.day, from: currentDate) : nil
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let dateString = formatter.string(from: currentDate)
                
                let isToday = calendar.isDate(currentDate, inSameDayAs: today)
                let weekday = calendar.component(.weekday, from: currentDate)
                let isSunday = weekday == 1
                let isSaturday = weekday == 7
                
                let dayTodos = todos.filter { $0.includesDate(currentDate) }
                
                let dayInfo = CalendarDayInfo(
                    day: day,
                    dateString: dateString,
                    isToday: isToday,
                    isSunday: isSunday,
                    isSaturday: isSaturday,
                    holidayName: nil,
                    todos: dayTodos
                )
                
                week.append(dayInfo)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            weeks.append(week)
        }
        
        let periodEvents = todos.filter { $0.isPeriodEvent }
        let singleDayEvents = todos.filter { !$0.isPeriodEvent }
        
        return CalendarEntry(
            date: today,
            currentMonth: month,
            weeks: weeks,
            allTodos: todos,
            periodEvents: periodEvents,
            singleDayEvents: singleDayEvents
        )
    }
    
    private func loadTodosFromICloud() -> [WidgetTodoItem] {
        // 위젯 확장에서는 안전하게 iCloud 접근
        do {
            let store = NSUbiquitousKeyValueStore.default
            let todosKey = "SavedTodos"
            
            store.synchronize()
            
            guard let data = store.data(forKey: todosKey) else {
                return []
            }
            
            let todos = try JSONDecoder().decode([WidgetTodoItem].self, from: data)
            return todos
        } catch {
            return []
        }
    }
}

// MARK: - Calendar Widget View

struct CalendarWidgetView: View {
    let entry: CalendarEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallCalendarView(entry: entry, colorScheme: colorScheme)
        case .systemLarge:
            LargeCalendarView(entry: entry, colorScheme: colorScheme)
        default:
            SmallCalendarView(entry: entry, colorScheme: colorScheme)
        }
    }
}

// MARK: - Small Calendar View

struct SmallCalendarView: View {
    let entry: CalendarEntry
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            // 월/년 표시
            Text(monthYearString)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(WidgetAppColors.textPrimary(colorScheme))
            
            // 4주 달력 그리드
            VStack(spacing: 2) {
                ForEach(Array(entry.weeks.prefix(4).enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 2) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, dayInfo in
                            DayCellView(dayInfo: dayInfo, colorScheme: colorScheme, size: .small)
                        }
                    }
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color.black : Color.white
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM"
        return formatter.string(from: entry.currentMonth)
    }
}

// MARK: - Large Calendar View

struct LargeCalendarView: View {
    let entry: CalendarEntry
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            
            // 년도/월 표시 (중앙 정렬)
            HStack {
                Spacer()
                Text(monthYearString)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(WidgetAppColors.textPrimary(colorScheme))
                Spacer()
            }
            .padding(.bottom, 10)
            
            // 요일 헤더
            HStack(spacing: 2) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(day == "일" ? WidgetAppColors.coralred(colorScheme) : 
                                       (day == "토" ? WidgetAppColors.skyblue(colorScheme) : 
                                       WidgetAppColors.textPrimary(colorScheme)))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)
            
            // 주별 달력 (각 날짜 셀 안에 일정 직접 표시)
            VStack(spacing: 0) {
                ForEach(Array(entry.weeks.enumerated()), id: \.offset) { weekIndex, week in
                    WeekCalendarView(
                        week: week,
                        colorScheme: colorScheme,
                        weekIndex: weekIndex
                    )
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .containerBackground(for: .widget) {
            colorScheme == .dark ? Color.black : Color.white
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter.string(from: entry.currentMonth)
    }
}

// MARK: - Week Calendar View

struct WeekCalendarView: View {
    let week: [CalendarDayInfo]
    let colorScheme: ColorScheme
    let weekIndex: Int
    
    var body: some View {
        GeometryReader { geometry in
            let cellWidth = (geometry.size.width - 10) / 7 // 좌우 간격을 위해 12pt 빼기
            let spacing: CGFloat = 2 // 날짜 셀 간 간격
            
            HStack(spacing: spacing) {
                ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, dayInfo in
                    DayCellWithEventsView(
                        dayInfo: dayInfo,
                        colorScheme: colorScheme,
                        dayIndex: dayIndex,
                        week: week
                    )
                    .frame(width: cellWidth)
                }
            }
            .padding(.horizontal, 3) // 좌우 여백
        }
        .frame(height: calculateWeekHeight())
    }
    
    private func calculateWeekHeight() -> CGFloat {
        // 각 날짜 셀의 최소 높이 계산
        let headerHeight: CGFloat = 22 // 날짜 헤더 (2 + 20)
        let eventHeight: CGFloat = 12
        let eventSpacing: CGFloat = 1
        let maxEventsPerDay = 2 // 1개 일정 + "+n개" 표시
        let eventAreaHeight = CGFloat(maxEventsPerDay) * (eventHeight + eventSpacing) + 3 // 여유 공간
        return headerHeight + eventAreaHeight + 2 // 하단 여유 공간
    }
}

// MARK: - Day Cell With Events View (위젯 전용: 각 날짜 셀 안에 일정 직접 표시)

struct DayCellWithEventsView: View {
    let dayInfo: CalendarDayInfo
    let colorScheme: ColorScheme
    let dayIndex: Int
    let week: [CalendarDayInfo]
    
    private let topPadding: CGFloat = 2
    private let dayLabelHeight: CGFloat = 14
    private let dayLabelToEventSpacing: CGFloat = 3
    private let eventHeight: CGFloat = 12
    private let eventSpacing: CGFloat = 1
    private let maxVisibleEvents: Int = 1 // 각 날짜별 최대 표시 일정 개수 (1개만 표시, 나머지는 +n개)
    
    var body: some View {
        VStack(spacing: 0) {
            // 날짜 헤더
            if let day = dayInfo.day {
                // 날짜 숫자
                ZStack {
                    if dayInfo.isToday {
                        Circle()
                            .fill(WidgetAppColors.textHighlighted(colorScheme))
                            .frame(width: 20, height: 20)
                    }
                    
                    Text("\(day)")
                        .font(.system(size: 11, weight: dayInfo.isToday ? .bold : .medium))
                        .foregroundColor(dayTextColor)
                }
                .frame(height: 20)
                .padding(.top, topPadding)
                
                // 일정 영역
                VStack(spacing: eventSpacing) {
                    let allEvents = getAllEventsForDay()
                    
                    if allEvents.isEmpty {
                        // 일정이 없으면 빈 공간
                        Spacer()
                            .frame(height: eventHeight)
                    } else if allEvents.count == 1 {
                        // 일정이 1개면 표시
                        EventCapsuleView(
                            text: allEvents[0].text,
                            color: WidgetAppColors.color(for: allEvents[0].colorName, scheme: colorScheme),
                            isPeriod: allEvents[0].isPeriodEvent
                        )
                    } else {
                        // 일정이 2개 이상이면 첫 번째 일정만 표시하고 나머지는 +n개로
                        EventCapsuleView(
                            text: allEvents[0].text,
                            color: WidgetAppColors.color(for: allEvents[0].colorName, scheme: colorScheme),
                            isPeriod: allEvents[0].isPeriodEvent
                        )
                        
                        Text("+\(allEvents.count - 1)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                            .frame(height: 10)
                    }
                }
                .padding(.top, dayLabelToEventSpacing)
                .padding(.horizontal, 0.5)
            } else {
                // 빈 날짜 셀
                Spacer()
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // 해당 날짜의 모든 일정 가져오기 (기간별 + 단일)
    private func getAllEventsForDay() -> [WidgetTodoItem] {
        var allEvents: [WidgetTodoItem] = []
        
        // 1. 해당 날짜의 단일 일정
        let singleEvents = dayInfo.todos.filter { !$0.isPeriodEvent }
        allEvents.append(contentsOf: singleEvents)
        
        // 2. 해당 날짜를 포함하는 기간별 일정 (주 내에서 찾기)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let currentDayDate = formatter.date(from: dayInfo.dateString) else {
            return allEvents
        }
        
        // 주 내의 모든 날짜를 확인하여 기간별 일정 찾기
        var periodEventIds: Set<UUID> = []
        for weekDayInfo in week {
            for todo in weekDayInfo.todos where todo.isPeriodEvent {
                // 중복 제거
                if periodEventIds.contains(todo.id) { continue }
                
                guard let startDateString = todo.startDate,
                      let endDateString = todo.endDate,
                      let startDate = formatter.date(from: startDateString),
                      let endDate = formatter.date(from: endDateString) else { continue }
                
                // 현재 날짜가 기간에 포함되는지 확인
                if currentDayDate >= startDate && currentDayDate <= endDate {
                    allEvents.append(todo)
                    periodEventIds.insert(todo.id)
                }
            }
        }
        
        return allEvents
    }
    
    
    private var dayTextColor: Color {
        if dayInfo.isToday {
            return Color.white
        } else if dayInfo.isSunday {
            return WidgetAppColors.coralred(colorScheme)
        } else if dayInfo.isSaturday {
            return WidgetAppColors.skyblue(colorScheme)
        } else {
            return WidgetAppColors.textPrimary(colorScheme)
        }
    }
}

// MARK: - Event Capsule View (위젯 전용)

struct EventCapsuleView: View {
    let text: String
    let color: Color
    let isPeriod: Bool
    
    private let eventHeight: CGFloat = 12
    private let fontSize: CGFloat = 8
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .frame(maxWidth: .infinity, minHeight: eventHeight, alignment: .leading)
            .background(color)
            .cornerRadius(3)
    }
}

// MARK: - Day Cell View (Small용)

enum DayCellSize {
    case small
    case large
}

struct DayCellView: View {
    let dayInfo: CalendarDayInfo
    let colorScheme: ColorScheme
    let size: DayCellSize
    
    private var cellSize: CGFloat {
        switch size {
        case .small: return 20
        case .large: return 36
        }
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .small: return 9
        case .large: return 13
        }
    }
    
    private var dotSize: CGFloat {
        switch size {
        case .small: return 4
        case .large: return 5
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            if let day = dayInfo.day {
                ZStack {
                    if dayInfo.isToday {
                        Circle()
                            .fill(WidgetAppColors.textHighlighted(colorScheme))
                            .frame(width: cellSize, height: cellSize)
                    }
                    
                    Text("\(day)")
                        .font(.system(size: fontSize, weight: dayInfo.isToday ? .bold : .medium))
                        .foregroundColor(dayTextColor)
                }
                .frame(width: cellSize, height: cellSize)
                
                if !dayInfo.todos.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(Array(dayInfo.todos.prefix(5).enumerated()), id: \.offset) { _, todo in
                            Circle()
                                .fill(WidgetAppColors.color(for: todo.colorName, scheme: colorScheme))
                                .frame(width: dotSize, height: dotSize)
                        }
                    }
                    .frame(height: dotSize + 2)
                } else {
                    Spacer()
                        .frame(height: dotSize + 2)
                }
            } else {
                Spacer()
                    .frame(width: cellSize, height: cellSize + dotSize + 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dayTextColor: Color {
        if dayInfo.isToday {
            return Color.white
        } else if dayInfo.isSunday {
            return WidgetAppColors.coralred(colorScheme)
        } else if dayInfo.isSaturday {
            return WidgetAppColors.skyblue(colorScheme)
        } else {
            return WidgetAppColors.textPrimary(colorScheme)
        }
    }
}

// MARK: - Widget

struct NowerCalendarWidget: Widget {
    let kind: String = "NowerCalendarWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("월 달력")
        .description("전체 월 달력과 일정을 한 눈에 확인합니다.")
        .supportedFamilies([
            .systemSmall,
            .systemLarge
        ])
    }
}

// MARK: - Preview

struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        let today = Date()
        let calendar = Calendar.current
        let month = calendar.dateInterval(of: .month, for: today)?.start ?? today
        
        let sampleTodos = [
            WidgetTodoItem(text: "샘플 일정 1", isRepeating: false, date: today, colorName: "skyblue"),
            WidgetTodoItem(text: "샘플 일정 2", isRepeating: false, date: today, colorName: "coralred")
        ]
        
        let provider = CalendarProvider()
        let entry = provider.generateCalendarEntry(for: month, todos: sampleTodos)
        
        CalendarWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
