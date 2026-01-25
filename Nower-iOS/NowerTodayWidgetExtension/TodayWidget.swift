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
                print("⚠️ [WidgetTodoItem] 기간별 일정이지만 startDate 또는 endDate가 nil: \(text)")
                return false
            }
            // 문자열 비교로 날짜 범위 확인
            let isIncluded = dateString >= start && dateString <= end
            if isIncluded {
                print("  ✅ 기간별 일정 포함 확인: \(text) (\(start) ~ \(end), 확인 날짜: \(dateString))")
            }
            return isIncluded
        } else {
            let isIncluded = self.date == dateString
            if isIncluded {
                print("  ✅ 단일 일정 포함 확인: \(text) (일정 날짜: \(self.date), 확인 날짜: \(dateString))")
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
    
    /// 테마 색상 이름으로 색상 가져오기
    static func color(for name: String, scheme: ColorScheme) -> Color {
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
    
    /// 테마 색상에 대비되는 텍스트 색상 (대부분의 테마 색상이 중간 명도이므로 흰색 사용)
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
        let entry = loadTodayEntry()

        // 다음 업데이트 시점: 15분 뒤 (배터리 고려)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// iCloud에 저장된 Todo들 중 오늘 포함 일정을 읽어와 Entry 생성
    private func loadTodayEntry() -> TodayEntry {
        let today = Date()
        
        // 오늘 날짜를 문자열로 변환 (디버깅용)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let todayString = formatter.string(from: today)
        print("📅 [TodayWidget] 오늘 날짜: \(todayString)")
        
        // 안전하게 iCloud 데이터 로드
        let allTodos: [WidgetTodoItem]
        do {
            allTodos = try loadTodosFromICloud()
            print("📦 [TodayWidget] 전체 일정 개수: \(allTodos.count)")
            
            // 디버깅: 모든 일정의 날짜 출력
            for (index, todo) in allTodos.enumerated() {
                print("  [\(index)] \(todo.text) | date: \(todo.date) | startDate: \(todo.startDate ?? "nil") | endDate: \(todo.endDate ?? "nil")")
            }
        } catch {
            // 에러 발생 시 빈 배열 반환
            print("⚠️ [TodayWidget] iCloud 데이터 로드 실패: \(error.localizedDescription)")
            return TodayEntry(date: today, todos: [])
        }

        // 오늘을 포함하는 일정 필터 (기간 일정 포함)
        let todayTodos = allTodos.filter { todo in
            let includes = todo.includesDate(today)
            if includes {
                print("✅ [TodayWidget] 오늘 일정 포함: \(todo.text) (date: \(todo.date))")
            }
            return includes
        }
        
        print("📋 [TodayWidget] 오늘 일정 개수: \(todayTodos.count)")

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
        print("🔍 [TodayWidget] iCloud store의 모든 키: \(Array(allKeys))")
        print("🔍 [TodayWidget] 찾는 키: '\(todosKey)'")
        
        // iCloud 접근 권한 확인
        guard let data = store.data(forKey: todosKey) else {
            print("⚠️ [TodayWidget] iCloud에 'SavedTodos' 키가 없습니다")
            print("⚠️ [TodayWidget] 사용 가능한 키: \(allKeys)")
            // 데이터가 없으면 빈 배열 반환 (에러 아님)
            return []
        }
        
        print("✅ [TodayWidget] iCloud에서 데이터 로드 성공 (크기: \(data.count) bytes)")

        // iOS 앱의 TodoItem과 동일한 구조이므로 JSON 디코딩 가능
        // 위젯에서는 WidgetTodoItem으로 디코딩
        let todos = try JSONDecoder().decode([WidgetTodoItem].self, from: data)
        print("✅ [TodayWidget] \(todos.count)개의 TodoItem 디코딩 완료")
        return todos
    }
}

// MARK: - View

struct TodayWidgetEntryView: View {
    let entry: TodayEntry
    @Environment(\.colorScheme) private var colorScheme

    // 오늘 일정 최대 2개까지만 표시
    private var visibleTodos: [WidgetTodoItem] {
        Array(entry.todos.prefix(2))
    }

    private var remainingCount: Int {
        max(entry.todos.count - visibleTodos.count, 0)
    }

    private var headerDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            VStack(alignment: .leading, spacing: 2) {
                Text("오늘의 일정")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(WidgetAppColors.textPrimary(colorScheme))

                Text(headerDateText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
            }

            // 일정 목록
            if visibleTodos.isEmpty {
                Spacer()
                Text("일정이 없습니다")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(visibleTodos, id: \.id) { todo in
                        CapsuleRow(todo: todo)
                    }

                    if remainingCount > 0 {
                        Text("+\(remainingCount)개 더 있음")
                            .font(.system(size: 11))
                            .foregroundColor(WidgetAppColors.textFieldPlaceholder(colorScheme))
                    }
                }
                .padding(.top, 4)
                Spacer()
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            // 다크모드: 검정, 라이트모드: 흰색
            colorScheme == .dark ? Color.black : Color.white
        }
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

/// 잠금화면 사각형 위젯 뷰 (일정 최대 2개까지 표시)
struct LockScreenRectangularView: View {
    let entry: TodayEntry

    private var visibleTodos: [WidgetTodoItem] {
        Array(entry.todos.prefix(2))
    }

    private var remainingCount: Int {
        max(entry.todos.count - visibleTodos.count, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nower")
                .font(.system(size: 12, weight: .bold))

            if visibleTodos.isEmpty {
                Text("일정 없음")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visibleTodos, id: \.id) { todo in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(WidgetAppColors.color(for: todo.colorName, scheme: .dark))
                            .frame(width: 4, height: 4)

                        Text(todo.text)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                }

                if remainingCount > 0 {
                    Text("+\(remainingCount)개")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

/// 잠금화면 인라인 위젯 뷰 (간단한 텍스트)
struct LockScreenInlineView: View {
    let entry: TodayEntry

    var body: some View {
        if entry.todos.isEmpty {
            Label("일정 없음", systemImage: "calendar")
        } else {
            Label("오늘 \(entry.todos.count)개 일정", systemImage: "calendar")
        }
    }
}

// MARK: - Widget

struct NowerTodayWidget: Widget {
    let kind: String = "NowerTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("오늘의 일정")
        .description("오늘 할 일과 기간 일정을 한 눈에 확인합니다.")
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

