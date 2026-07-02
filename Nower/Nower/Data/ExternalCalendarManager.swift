//
//  ExternalCalendarManager.swift
//  Nower (macOS)
//
//  외부 캘린더(Phase 1: Apple/EventKit) 읽기 전용 연동 매니저.
//  iOS(Nower-iOS)와 동작을 맞춘 macOS 미러. provider에서 이벤트를 가져와
//  읽기 전용 TodoItem으로 매핑한다.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation
import NowerCore

final class ExternalCalendarManager {
    static let shared = ExternalCalendarManager()

    /// 외부 캘린더 연동 상태(on/off·권한)가 바뀌었음을 알린다. 옵저버는 재fetch한다.
    static let didChangeNotification = Notification.Name("ExternalCalendarManager.didChange")

    /// externalTodos가 실제로 갱신됐음을 알린다(fetch 완료 후). 화면은 이때 리로드한다.
    static let externalTodosDidChangeNotification = Notification.Name("ExternalCalendarManager.externalTodosDidChange")

    private let appleProvider = AppleCalendarProvider()
    private let appleEnabledKey = "external.apple.enabled"

    private init() {}

    // MARK: - Apple 연동 on/off

    var isAppleEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: appleEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: appleEnabledKey) }
    }

    /// Apple 연동을 켜고/끄고 변경 알림을 발행한다(→ CalendarViewModel 재fetch).
    func setAppleEnabled(_ enabled: Bool) {
        isAppleEnabled = enabled
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    /// Apple 캘린더 접근이 이미 허용된 상태인지.
    var isAppleAuthorized: Bool { AppleCalendarProvider.isAuthorized }

    /// Apple 캘린더 접근 권한을 요청한다.
    func requestAppleAccess() async -> Bool {
        await appleProvider.authorize()
    }

    // MARK: - Fetch

    /// 활성화된 외부 소스의 일정을 넓은 창(기준일 ±6개월)으로 가져와 읽기 전용 TodoItem으로 매핑한다.
    /// 비활성/미허가면 빈 배열(→ setExternalTodos가 replace-all로 유령 제거).
    func fetchExternalTodos(around date: Date = Date()) async -> [TodoItem] {
        var result: [TodoItem] = []

        if isAppleEnabled, isAppleAuthorized {
            let calendar = Calendar.current
            let start = calendar.date(byAdding: .month, value: -6, to: date) ?? date
            let end = calendar.date(byAdding: .month, value: 6, to: date) ?? date
            let range = DateInterval(start: start, end: max(end, start))
            let events = (try? await appleProvider.fetchEvents(in: range)) ?? []

            // iOS와 동일: "대한민국 공휴일" 구독 캘린더에서 온 이벤트는 제외한다.
            // (macOS엔 아직 휴일 라벨이 없어 휴일은 표시되지 않으며, 후일 휴일 API를
            //  붙이면 iOS처럼 라벨이 단일 진실이 되도록 캡슐을 미리 흡수해 둔다.)
            let personal = events.filter { !Self.isHolidayCalendar($0.calendarTitle) }
            result.append(contentsOf: personal.map { $0.toTodoItem() })
        }

        Self.persistForWidgets(result)
        return result
    }

    /// iOS 기본 공휴일/휴일 구독 캘린더 이름인지. 로케일 대비 한/영 키워드 모두 매칭.
    private static func isHolidayCalendar(_ title: String) -> Bool {
        let lower = title.lowercased()
        return title.contains("휴일") || lower.contains("holiday")
    }

    /// 위젯(별도 프로세스)이 외부 일정을 볼 수 있도록 iCloud KVS 별도 키에 replace-all로 저장한다.
    /// 메인 앱은 이 키를 자기 할일로 다시 읽지 않는다(유령 방지). 비활성/미허가면 []로 덮어써 정리.
    static let widgetExternalTodosKey = "SavedExternalTodos"
    private static func persistForWidgets(_ todos: [TodoItem]) {
        let store = NSUbiquitousKeyValueStore.default
        if let data = try? JSONEncoder().encode(todos) {
            store.set(data, forKey: widgetExternalTodosKey)
            store.synchronize()
        }
    }

    // MARK: - 읽기 전용 안내(가드) 헬퍼

    /// externalSource 코드("apple"/"google"/"naver")를 사용자용 이름으로 변환한다.
    static func externalSourceDisplayName(_ source: String?) -> String {
        switch source {
        case "apple": return "Apple 캘린더"
        case "google": return "Google 캘린더"
        case "naver": return "네이버 캘린더"
        default: return "외부 캘린더"
        }
    }

    /// 읽기 전용(외부) 일정 탭 시 편집 대신 보여줄 안내 문구.
    static func readOnlyNoticeMessage(for todo: TodoItem) -> String {
        "\(externalSourceDisplayName(todo.externalSource)) 일정은 읽기 전용이에요. Nower에서 수정·삭제는 안 돼요."
    }
}
