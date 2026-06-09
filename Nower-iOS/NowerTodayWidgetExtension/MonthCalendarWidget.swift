//
//  MonthCalendarWidget.swift
//  NowerTodayWidgetExtension
//
//  iOS 월간 캘린더 위젯
//  macOS NowerCalendarWidget.swift를 iOS용으로 포팅
//  - WidgetTodoItem, WidgetAppColors는 TodayWidget.swift에서 공유
//

import WidgetKit
import SwiftUI
import Foundation

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

// MARK: - Calendar Provider

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        let today = Date()
        let month = Calendar.current.dateInterval(of: .month, for: today)?.start ?? today
        return generateCalendarEntry(for: month, todos: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let today = Date()
        let month = Calendar.current.dateInterval(of: .month, for: today)?.start ?? today
        let todos = loadTodosFromICloud()
        let entry = generateCalendarEntry(for: month, todos: todos)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
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

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        var weeks: [[CalendarDayInfo]] = []
        var currentDate = firstSunday

        for _ in 0..<6 {
            var week: [CalendarDayInfo] = []
            for _ in 0..<7 {
                let isInMonth = calendar.isDate(currentDate, equalTo: month, toGranularity: .month)
                let day = isInMonth ? calendar.component(.day, from: currentDate) : nil
                let dateString = formatter.string(from: currentDate)
                let isToday = calendar.isDate(currentDate, inSameDayAs: today)
                let weekday = calendar.component(.weekday, from: currentDate)

                let dayInfo = CalendarDayInfo(
                    day: day,
                    dateString: dateString,
                    isToday: isToday,
                    isSunday: weekday == 1,
                    isSaturday: weekday == 7,
                    holidayName: nil,
                    todos: todos.filter { $0.includesDate(currentDate) }
                )
                week.append(dayInfo)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            weeks.append(week)
        }

        return CalendarEntry(
            date: today,
            currentMonth: month,
            weeks: weeks,
            allTodos: todos,
            periodEvents: todos.filter { $0.isPeriodEvent },
            singleDayEvents: todos.filter { !$0.isPeriodEvent }
        )
    }

    private func loadTodosFromICloud() -> [WidgetTodoItem] {
        do {
            let store = NSUbiquitousKeyValueStore.default
            store.synchronize()
            guard let data = store.data(forKey: "SavedTodos") else { return [] }
            return try JSONDecoder().decode([WidgetTodoItem].self, from: data)
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
        case .systemMedium:
            MediumCalendarView(entry: entry, colorScheme: colorScheme)
        case .systemLarge:
            LargeCalendarView(entry: entry, colorScheme: colorScheme)
        default:
            MediumCalendarView(entry: entry, colorScheme: colorScheme)
        }
    }
}

// MARK: - Medium Calendar View (4주 컴팩트 그리드)

struct MediumCalendarView: View {
    let entry: CalendarEntry
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 4) {
            Text(monthYearString)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(WidgetAppColors.textPrimary(colorScheme))

            VStack(spacing: 2) {
                ForEach(Array(entry.weeks.prefix(4).enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 2) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, dayInfo in
                            DayCellView(dayInfo: dayInfo, colorScheme: colorScheme)
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

// MARK: - Large Calendar View (6주 전체 그리드 + 이벤트 캡슐)

struct LargeCalendarView: View {
    let entry: CalendarEntry
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            HStack {
                Spacer()
                Text(monthYearString)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(WidgetAppColors.textPrimary(colorScheme))
                Spacer()
            }
            .padding(.bottom, 10)

            HStack(spacing: 2) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(
                            day == "일" ? WidgetAppColors.coralred(colorScheme) :
                            day == "토" ? WidgetAppColors.skyblue(colorScheme) :
                            WidgetAppColors.textPrimary(colorScheme)
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            VStack(spacing: 0) {
                ForEach(Array(entry.weeks.enumerated()), id: \.offset) { weekIndex, week in
                    WeekCalendarView(week: week, colorScheme: colorScheme, weekIndex: weekIndex)
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
            let cellWidth = (geometry.size.width - 10) / 7
            HStack(spacing: 2) {
                ForEach(Array(week.enumerated()), id: \.offset) { _, dayInfo in
                    DayCellWithEventsView(dayInfo: dayInfo, colorScheme: colorScheme, week: week)
                        .frame(width: cellWidth)
                }
            }
            .padding(.horizontal, 3)
        }
        .frame(height: 57)
    }
}

// MARK: - Day Cell With Events View

struct DayCellWithEventsView: View {
    let dayInfo: CalendarDayInfo
    let colorScheme: ColorScheme
    let week: [CalendarDayInfo]

    private let eventHeight: CGFloat = 12
    private let eventSpacing: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            if let day = dayInfo.day {
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
                .padding(.top, 2)

                VStack(spacing: eventSpacing) {
                    let allEvents = getAllEventsForDay()
                    if allEvents.isEmpty {
                        Spacer().frame(height: eventHeight)
                    } else if allEvents.count == 1 {
                        EventCapsuleView(
                            text: allEvents[0].text,
                            color: WidgetAppColors.color(for: allEvents[0].colorName, scheme: colorScheme),
                            isPeriod: allEvents[0].isPeriodEvent
                        )
                    } else {
                        EventCapsuleView(
                            text: allEvents[0].text,
                            color: WidgetAppColors.color(for: allEvents[0].colorName, scheme: colorScheme),
                            isPeriod: allEvents[0].isPeriodEvent
                        )
                        Text("외 \(allEvents.count - 1)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                            .frame(height: 10)
                    }
                }
                .padding(.top, 3)
                .padding(.horizontal, 0.5)
            } else {
                Spacer()
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func getAllEventsForDay() -> [WidgetTodoItem] {
        var allEvents = dayInfo.todos.filter { !$0.isPeriodEvent }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard let currentDayDate = formatter.date(from: dayInfo.dateString) else { return allEvents }

        var seen: Set<UUID> = []
        for weekDayInfo in week {
            for todo in weekDayInfo.todos where todo.isPeriodEvent {
                guard !seen.contains(todo.id),
                      let startStr = todo.startDate, let endStr = todo.endDate,
                      let startDate = formatter.date(from: startStr),
                      let endDate = formatter.date(from: endStr),
                      currentDayDate >= startDate && currentDayDate <= endDate else { continue }
                allEvents.append(todo)
                seen.insert(todo.id)
            }
        }
        return allEvents
    }

    private var dayTextColor: Color {
        if dayInfo.isToday { return .white }
        if dayInfo.isSunday { return WidgetAppColors.coralred(colorScheme) }
        if dayInfo.isSaturday { return WidgetAppColors.skyblue(colorScheme) }
        return WidgetAppColors.textPrimary(colorScheme)
    }
}

// MARK: - Event Capsule View

struct EventCapsuleView: View {
    let text: String
    let color: Color
    let isPeriod: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .frame(maxWidth: .infinity, minHeight: 12, alignment: .leading)
            .background(color)
            .cornerRadius(3)
    }
}

// MARK: - Day Cell View (Medium용 컴팩트)

struct DayCellView: View {
    let dayInfo: CalendarDayInfo
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 2) {
            if let day = dayInfo.day {
                ZStack {
                    if dayInfo.isToday {
                        Circle()
                            .fill(WidgetAppColors.textHighlighted(colorScheme))
                            .frame(width: 20, height: 20)
                    }
                    Text("\(day)")
                        .font(.system(size: 9, weight: dayInfo.isToday ? .bold : .medium))
                        .foregroundColor(dayTextColor)
                }
                .frame(width: 20, height: 20)

                if !dayInfo.todos.isEmpty {
                    // 일정명 대신 점으로만 가볍게 (월의 리듬). 최대 3개.
                    HStack(spacing: 3) {
                        ForEach(Array(dayInfo.todos.prefix(3).enumerated()), id: \.offset) { _, todo in
                            Circle()
                                .fill(WidgetAppColors.color(for: todo.colorName, scheme: colorScheme))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 6)
                } else {
                    Spacer().frame(height: 6)
                }
            } else {
                Spacer().frame(width: 20, height: 26)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dayTextColor: Color {
        if dayInfo.isToday { return .white }
        if dayInfo.isSunday { return WidgetAppColors.coralred(colorScheme) }
        if dayInfo.isSaturday { return WidgetAppColors.skyblue(colorScheme) }
        return WidgetAppColors.textPrimary(colorScheme)
    }
}

// MARK: - Widget

struct NowerMonthCalendarWidget: Widget {
    let kind: String = "NowerMonthCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("이번 달의 리듬")
        .description("일정을 점으로 가볍게 — 이번 달의 리듬을 한눈에.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Preview

struct MonthCalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        let today = Date()
        let month = Calendar.current.dateInterval(of: .month, for: today)?.start ?? today
        let sampleTodos = [
            WidgetTodoItem(text: "샘플 일정 1", isRepeating: false, date: today, colorName: "skyblue"),
            WidgetTodoItem(text: "샘플 일정 2", isRepeating: false, date: today, colorName: "coralred")
        ]
        let entry = CalendarProvider().generateCalendarEntry(for: month, todos: sampleTodos)

        CalendarWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
