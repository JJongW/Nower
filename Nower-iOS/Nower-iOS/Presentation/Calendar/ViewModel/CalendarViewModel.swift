//
//  CalendarViewModel.swift
//  Nower-iOS
//
//  Created by 신종원 on 5/3/25.
//

import Foundation
import Combine

final class CalendarViewModel: ObservableObject {
    private let addTodoUseCase: AddTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    private let updateTodoUseCase: UpdateTodoUseCase
    private let getTodosByDateUseCase: GetTodosByDateUseCase
    private let loadAllTodosUseCase: LoadAllTodosUseCase
    private let holidayUseCase: HolidayUseCase

    @Published var todosByDate: [String: [TodoItem]] = [:]
    @Published var selectedDate: Date?
    @Published var todoText: String = ""
    @Published var isRepeating: Bool = false
    @Published var selectedColorName: String = "default"
    @Published var selectedColor: String = "skyblue"
    
    // 기간별 일정을 위한 새로운 프로퍼티
    @Published var selectedStartDate: Date?
    @Published var selectedEndDate: Date?

    // 시간/알림 프로퍼티
    @Published var selectedScheduledTime: String?      // "HH:mm" or nil
    @Published var selectedEndScheduledTime: String?   // "HH:mm" or nil (기간별 일정 종료 시간)
    @Published var selectedReminderMinutesBefore: Int?  // minutes or nil

    // 반복 일정 프로퍼티
    @Published var selectedRecurrenceInfo: RecurrenceInfo?

    /// 모든 반복 일정 캐시 (loadAllTodos에서 분리 저장)
    private(set) var allRecurringTodos: [TodoItem] = []

    init(
        addTodoUseCase: AddTodoUseCase,
        deleteTodoUseCase: DeleteTodoUseCase,
        updateTodoUseCase: UpdateTodoUseCase,
        getTodosByDateUseCase: GetTodosByDateUseCase,
        loadAllTodosUseCase: LoadAllTodosUseCase,
        holidayUseCase: HolidayUseCase
    ) {
        self.addTodoUseCase = addTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.updateTodoUseCase = updateTodoUseCase
        self.getTodosByDateUseCase = getTodosByDateUseCase
        self.loadAllTodosUseCase = loadAllTodosUseCase
        self.holidayUseCase = holidayUseCase

        loadAllTodos()
        setupNotificationObserver()
        refreshDepartureNudges() // 앱 시작 시 출발 알림 재동기화
    }

    func loadAllTodos() {
        NSUbiquitousKeyValueStore.default.synchronize()

        todosByDate = [:]
        allRecurringTodos = []
        let allTodos = loadAllTodosUseCase.execute()
        for todo in allTodos {
            if todo.isRecurringEvent {
                allRecurringTodos.append(todo)
            }
            todosByDate[todo.date, default: []].append(todo)
        }
    }

    func todos(for date: Date) -> [TodoItem] {
        let key = date.toDateString()
        let todosForDate = todosByDate[key] ?? []

        // 해당 날짜의 단일 날짜 일정들만 필터링 (기간별 일정 및 반복 원본 제외)
        let singleDayTodos = todosForDate.filter { !$0.isPeriodEvent && !$0.isRecurringEvent }

        // 단일 날짜 일정을 시간순으로 정렬: 시간이 있는 일정은 시간 순서대로, 하루 종일 일정은 맨 아래에 배치
        let sortedSingleDayTodos = singleDayTodos.sorted { todo1, todo2 in
            // 둘 다 시간이 있는 경우: 시간 순서대로 정렬
            if let time1 = todo1.scheduledTime, let time2 = todo2.scheduledTime {
                return time1 < time2
            }
            // todo1만 시간이 있는 경우: todo1을 위로
            if todo1.scheduledTime != nil && todo2.scheduledTime == nil {
                return true
            }
            // todo2만 시간이 있는 경우: todo2를 위로
            if todo1.scheduledTime == nil && todo2.scheduledTime != nil {
                return false
            }
            // 둘 다 시간이 없는 경우: 원래 순서 유지 (제목순)
            return todo1.text < todo2.text
        }

        // 모든 일정에서 기간별 일정을 찾되 중복 제거
        let allTodos = todosByDate.values.flatMap { $0 }
        let uniquePeriodTodos = Array(Set(allTodos.filter { todo in
            todo.isPeriodEvent && todo.includesDate(date) && !todo.isRecurringEvent
        }))

        // 기간별 일정을 시작일 순으로 정렬
        let sortedPeriodTodos = uniquePeriodTodos.sorted { first, second in
            guard let firstStart = first.startDateObject,
                  let secondStart = second.startDateObject else { return false }
            return firstStart < secondStart
        }

        // 반복 일정의 가상 인스턴스 생성
        var recurringInstances: [TodoItem] = []
        var seenIds: Set<UUID> = []
        for todo in allRecurringTodos {
            if let instance = RecurringEventExpander.occurrence(of: todo, on: date), !seenIds.contains(todo.id) {
                seenIds.insert(todo.id)
                recurringInstances.append(instance)
            }
        }

        // 반복 가상 인스턴스를 시간순으로 정렬
        let sortedRecurringInstances = recurringInstances.sorted { todo1, todo2 in
            if let time1 = todo1.scheduledTime, let time2 = todo2.scheduledTime {
                return time1 < time2
            }
            if todo1.scheduledTime != nil && todo2.scheduledTime == nil { return true }
            if todo1.scheduledTime == nil && todo2.scheduledTime != nil { return false }
            return todo1.text < todo2.text
        }

        // 기간별 일정 → 반복 인스턴스 → 단일 일정 순서로 반환
        return sortedPeriodTodos + sortedRecurringInstances + sortedSingleDayTodos
    }

    func holidayName(for date: Date) -> String? {
        return holidayUseCase.holidayName(for: date)
    }

    func preloadHolidays(baseDate: Date) {
        holidayUseCase.preloadAdjacentMonths(baseDate: baseDate, completion: nil)
    }

    func addTodo() {
        guard let date = selectedDate, !todoText.isEmpty else { return }
        let hasRecurrence = selectedRecurrenceInfo != nil
        let newTodo = TodoItem(text: todoText, isRepeating: hasRecurrence || isRepeating, date: date.toDateString(), colorName: selectedColorName, scheduledTime: selectedScheduledTime, endScheduledTime: selectedEndScheduledTime, reminderMinutesBefore: selectedReminderMinutesBefore, recurrenceInfo: selectedRecurrenceInfo)
        addTodoUseCase.execute(todo: newTodo)
        if newTodo.isRecurringEvent {
            LocalNotificationManager.shared.scheduleRecurringNotifications(for: newTodo)
        } else {
            LocalNotificationManager.shared.scheduleNotification(for: newTodo)
        }
        scheduleDepartureNudge(for: newTodo)
    }
    
    /// 기간별 일정을 추가합니다.
    func addPeriodTodo() {
        guard let startDate = selectedStartDate,
              let endDate = selectedEndDate,
              !todoText.isEmpty else { return }

        let newTodo = TodoItem(text: todoText,
                              isRepeating: isRepeating,
                              startDate: startDate,
                              endDate: endDate,
                              colorName: selectedColorName,
                              scheduledTime: selectedScheduledTime,
                              endScheduledTime: selectedEndScheduledTime,
                              reminderMinutesBefore: selectedReminderMinutesBefore)
        addTodoUseCase.execute(todo: newTodo)
        LocalNotificationManager.shared.scheduleNotification(for: newTodo)
        scheduleDepartureNudge(for: newTodo)
    }

    func deleteTodo(_ todo: TodoItem) {
        LocalNotificationManager.shared.cancelNotification(for: todo.id)
        LocalNotificationManager.shared.cancelSeriesNotifications(for: todo.id)
        DepartureNudgeManager.shared.cancel(for: todo.id)
        deleteTodoUseCase.execute(todo: todo)
    }

    // MARK: - Recurring Event CRUD

    /// 반복 일정을 삭제합니다.
    /// - Parameters:
    ///   - todo: 원본 반복 일정
    ///   - occurrenceDate: 선택된 인스턴스의 날짜
    ///   - scope: 삭제 범위
    func deleteRecurringTodo(_ todo: TodoItem, occurrenceDate: Date, scope: RecurrenceEditScope) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: occurrenceDate)

        // 원본을 allRecurringTodos와 todosByDate에서 찾기
        guard let original = findOriginalRecurringTodo(for: todo) else {
            // 원본을 찾지 못하면 그냥 삭제
            deleteTodo(todo)
            return
        }

        switch scope {
        case .thisOnly:
            // 이 인스턴스만 삭제 (예외 추가)
            let exception = RecurrenceException(originalDate: dateString, isDeleted: true, overriddenTodo: nil)
            var exceptions = original.recurrenceExceptions ?? []
            exceptions.append(exception)
            let updated = original.withExceptions(exceptions)
            updateTodoUseCase.execute(original: original, updated: updated)

        case .thisAndFuture:
            // 이 날짜 이후 모든 일정 종료 (endDate 설정)
            guard var info = original.recurrenceInfo else { return }
            // occurrenceDate 하루 전을 종료일로 설정
            let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: occurrenceDate)
            let endDateStr = previousDay.map { formatter.string(from: $0) }
            info = RecurrenceInfo(frequency: info.frequency, interval: info.interval, endDate: endDateStr, endAfterCount: nil, daysOfWeek: info.daysOfWeek, dayOfMonth: info.dayOfMonth)
            let updated = original.withRecurrenceInfo(info)
            updateTodoUseCase.execute(original: original, updated: updated)

        case .all:
            // 전체 시리즈 삭제
            LocalNotificationManager.shared.cancelSeriesNotifications(for: original.id)
            deleteTodoUseCase.execute(todo: original)
        }

        loadAllTodos()
    }

    /// 반복 일정을 수정합니다.
    /// - Parameters:
    ///   - original: 원본 반복 일정
    ///   - updated: 수정된 데이터
    ///   - occurrenceDate: 선택된 인스턴스의 날짜
    ///   - scope: 수정 범위
    func updateRecurringTodo(original: TodoItem, updated: TodoItem, occurrenceDate: Date, scope: RecurrenceEditScope) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: occurrenceDate)

        guard let source = findOriginalRecurringTodo(for: original) else {
            // 원본을 찾지 못하면 일반 업데이트
            updateTodoUseCase.execute(original: original, updated: updated)
            return
        }

        switch scope {
        case .thisOnly:
            // 이 인스턴스만 수정 (예외로 override 추가)
            let exception = RecurrenceException(originalDate: dateString, isDeleted: false, overriddenTodo: updated)
            var exceptions = source.recurrenceExceptions ?? []
            // 기존 같은 날짜 예외 제거
            exceptions.removeAll { $0.originalDate == dateString }
            exceptions.append(exception)
            let updatedSource = source.withExceptions(exceptions)
            updateTodoUseCase.execute(original: source, updated: updatedSource)

        case .thisAndFuture:
            // 원본 시리즈를 이 날짜 전에서 종료
            guard var oldInfo = source.recurrenceInfo else { return }
            let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: occurrenceDate)
            let endDateStr = previousDay.map { formatter.string(from: $0) }
            oldInfo = RecurrenceInfo(frequency: oldInfo.frequency, interval: oldInfo.interval, endDate: endDateStr, endAfterCount: nil, daysOfWeek: oldInfo.daysOfWeek, dayOfMonth: oldInfo.dayOfMonth)
            let truncated = source.withRecurrenceInfo(oldInfo)
            updateTodoUseCase.execute(original: source, updated: truncated)

            // 새 시리즈 생성 (이 날짜부터)
            let newTodo = TodoItem(
                text: updated.text,
                isRepeating: true,
                date: dateString,
                colorName: updated.colorName,
                scheduledTime: updated.scheduledTime,
                reminderMinutesBefore: updated.reminderMinutesBefore,
                recurrenceInfo: updated.recurrenceInfo ?? source.recurrenceInfo,
                recurrenceSeriesId: source.id
            )
            addTodoUseCase.execute(todo: newTodo)

        case .all:
            // 모든 일정 수정 — 원본 자체를 업데이트
            let updatedAll = TodoItem(
                id: source.id,
                text: updated.text,
                isRepeating: true,
                date: source.date,
                colorName: updated.colorName,
                scheduledTime: updated.scheduledTime,
                reminderMinutesBefore: updated.reminderMinutesBefore,
                recurrenceInfo: updated.recurrenceInfo ?? source.recurrenceInfo,
                recurrenceExceptions: source.recurrenceExceptions,
                recurrenceSeriesId: source.recurrenceSeriesId
            )
            LocalNotificationManager.shared.cancelSeriesNotifications(for: source.id)
            DepartureNudgeManager.shared.cancel(for: source.id)
            updateTodoUseCase.execute(original: source, updated: updatedAll)
            LocalNotificationManager.shared.scheduleRecurringNotifications(for: updatedAll)
            scheduleDepartureNudge(for: updatedAll)
        }

        loadAllTodos()
    }

    /// 가상 인스턴스로부터 원본 반복 일정을 찾습니다.
    private func findOriginalRecurringTodo(for todo: TodoItem) -> TodoItem? {
        return allRecurringTodos.first { $0.id == todo.id }
    }

    func updateTodo(original: TodoItem, updatedText: String, updatedColor: String, date: Date? = nil, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil) {
        let targetDate = date ?? original.dateObject ?? Date()
        let dateString = targetDate.toDateString()
        let updatedTodo = TodoItem(text: updatedText, isRepeating: isRepeating, date: dateString, colorName: updatedColor, scheduledTime: scheduledTime, endScheduledTime: endScheduledTime, reminderMinutesBefore: reminderMinutesBefore)
        LocalNotificationManager.shared.cancelNotification(for: original.id)
        DepartureNudgeManager.shared.cancel(for: original.id)
        updateTodoUseCase.execute(original: original, updated: updatedTodo)
        LocalNotificationManager.shared.scheduleNotification(for: updatedTodo)
        scheduleDepartureNudge(for: updatedTodo)
    }

    /// 기간별 일정을 수정합니다.
    func updatePeriodTodo(original: TodoItem, updatedText: String, updatedColor: String, startDate: Date, endDate: Date, scheduledTime: String? = nil, endScheduledTime: String? = nil, reminderMinutesBefore: Int? = nil) {
        let updatedTodo = TodoItem(text: updatedText,
                                  isRepeating: isRepeating,
                                  startDate: startDate,
                                  endDate: endDate,
                                  colorName: updatedColor,
                                  scheduledTime: scheduledTime,
                                  endScheduledTime: endScheduledTime,
                                  reminderMinutesBefore: reminderMinutesBefore)
        LocalNotificationManager.shared.cancelNotification(for: original.id)
        DepartureNudgeManager.shared.cancel(for: original.id)
        updateTodoUseCase.execute(original: original, updated: updatedTodo)
        LocalNotificationManager.shared.scheduleNotification(for: updatedTodo)
        scheduleDepartureNudge(for: updatedTodo)
    }

    // MARK: - 출발 알림 (Departure Nudge)

    /// 빈 고정 슬롯(집/회사) 관련 일정을 만났을 때 1회만 호출됩니다. 위치 설정 권유 UI를 띄우는 용도.
    var onSuggestDepartureSetup: ((PlaceKind) -> Void)?

    /// 첫 출발 알림이 잡혔는데 준비 버퍼를 아직 안 물어봤을 때 1회만 호출됩니다. 버퍼 질문 UI를 띄우는 용도.
    var onAskBufferSeed: (() -> Void)?

    /// 단일 일정의 출발 알림을 백그라운드로 예약합니다.
    /// 매칭/좌표 조건을 못 맞추면 매니저가 조용히 건너뜁니다.
    private func scheduleDepartureNudge(for todo: TodoItem) {
        Task { [weak self] in
            let scheduled = await DepartureNudgeManager.shared.scheduleNudge(for: todo)
            if scheduled {
                await MainActor.run { self?.maybeAskBufferSeed() }
            }
        }
        maybeSuggestDepartureSetup(for: todo)
    }

    /// 첫 출발 알림이 실제로 잡혔을 때, 준비 버퍼를 1회 물어봅니다. (US-E1)
    private func maybeAskBufferSeed() {
        guard !DepartureNudgeManager.shared.hasSeededBuffer else { return }
        DepartureNudgeManager.shared.markBufferSeeded()
        onAskBufferSeed?()
    }

    /// 집/회사 위치가 비어 있는데 관련 일정을 만들면 "위치 넣으면 알려줄게요"를 1회 권유합니다.
    private func maybeSuggestDepartureSetup(for todo: TodoItem) {
        guard let kind = DepartureNudgeManager.shared.setupSuggestion(for: todo) else { return }
        DepartureNudgeManager.shared.markSetupSuggested()
        DispatchQueue.main.async { [weak self] in
            self?.onSuggestDepartureSetup?(kind)
        }
    }

    /// 저장된 모든 일정의 출발 알림을 다시 계산·예약합니다.
    /// 앱 시작 시, 또는 저장 장소 설정이 바뀌었을 때 호출합니다.
    func refreshDepartureNudges() {
        let todos = loadAllTodosUseCase.execute()
        Task { await DepartureNudgeManager.shared.refreshAll(todos: todos) }
    }

    @objc private func savedPlacesDidUpdate() {
        refreshDepartureNudges()
    }

    // MARK: - Private Methods
    
    /// CloudSyncManager 알림 옵저버를 설정합니다.
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(todosDidUpdate),
            name: Notification.Name("CloudSyncManager.todosDidUpdate"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savedPlacesDidUpdate),
            name: SavedPlacesManager.didUpdateNotification,
            object: nil
        )
    }
    
    /// Todo 업데이트 알림을 처리합니다.
    @objc private func todosDidUpdate() {
        DispatchQueue.main.async {
            self.loadAllTodos()
        }
    }
}
