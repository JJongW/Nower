//
//  ExternalCalendarManager.swift
//  Nower-iOS
//
//  외부 캘린더(Phase 1: Apple/EventKit) 읽기 전용 연동 매니저.
//  provider에서 이벤트를 가져와 읽기 전용 TodoItem으로 매핑한다.
//  Copyright © 2025 Nower. All rights reserved.
//

import Foundation
import NowerCore

final class ExternalCalendarManager {
    static let shared = ExternalCalendarManager()

    /// 외부 캘린더 연동 상태(on/off·권한)가 바뀌었음을 알린다. 옵저버는 재fetch한다.
    static let didChangeNotification = Notification.Name("ExternalCalendarManager.didChange")

    /// externalTodos가 실제로 갱신됐음을 알린다(fetch 완료 후). UIKit 화면은 이때 리로드한다.
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

            // iOS 기본 "공휴일" 구독 캘린더에서 온 이벤트는 제외한다.
            // 휴일(대체공휴일 포함)은 공공데이터포털 API 라벨이 단일 진실이므로,
            // Apple 공휴일 캡슐은 이름이 달라도(예: "대체 공휴일") 통째로 흡수한다.
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
}
