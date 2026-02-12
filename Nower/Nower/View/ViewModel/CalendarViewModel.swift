//
//  CalendarViewModel.swift
//  Nower
//
//  Created by 신종원 on 3/9/25.
//  Refactored for Clean Architecture on 5/12/25.
//
import SwiftUI
import Foundation

/// 달력 화면의 ViewModel
/// Clean Architecture 패턴을 적용하여 UseCase를 통해 비즈니스 로직을 처리합니다.
/// iOS 버전과 동일한 기능을 제공하며, 기간별 일정 및 공휴일 지원을 포함합니다.
class CalendarViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var dates: [CalendarDay] = [] // 하위 호환성을 위해 유지
    @Published var weeks: [[WeekDayInfo]] = [] // 주별 달력 데이터 (iOS 버전과 동일)
    @Published var currentMonth: Date = Date()
    @Published var isAddingEvent: Bool = false
    @Published var selectedEventType: EventType = .normal

    // iOS 버전과의 호환성을 위한 추가 프로퍼티
    @Published var todosByDate: [String: [TodoItem]] = [:]
    @Published var selectedDate: Date?
    @Published var todoText: String = ""
    @Published var isRepeating: Bool = false
    @Published var selectedColorName: String = "skyblue"

    // 기간별 일정을 위한 새로운 프로퍼티
    @Published var selectedStartDate: Date?
    @Published var selectedEndDate: Date?

    // 시간/알림 프로퍼티 (iOS 버전과 호환)
    @Published var selectedScheduledTime: String?      // "HH:mm" or nil
    @Published var selectedReminderMinutesBefore: Int?  // minutes or nil

    // 반복 일정 프로퍼티
    @Published var selectedRecurrenceInfo: RecurrenceInfo?

    /// 모든 반복 일정 캐시 (loadAllTodos에서 분리 저장)
    private(set) var allRecurringTodos: [TodoItem] = []

    // MARK: - UseCase Dependencies
    private let addTodoUseCase: AddTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    private let updateTodoUseCase: UpdateTodoUseCase
    private let getTodosByDateUseCase: GetTodosByDateUseCase
    private let loadAllTodosUseCase: LoadAllTodosUseCase
    private let moveTodoUseCase: MoveTodoUseCase
    private let holidayUseCase: HolidayUseCase?

    // MARK: - Initialization
    init(
        addTodoUseCase: AddTodoUseCase = DefaultAddTodoUseCase(repository: TodoRepositoryImpl()),
        deleteTodoUseCase: DeleteTodoUseCase = DefaultDeleteTodoUseCase(repository: TodoRepositoryImpl()),
        updateTodoUseCase: UpdateTodoUseCase = DefaultUpdateTodoUseCase(repository: TodoRepositoryImpl()),
        getTodosByDateUseCase: GetTodosByDateUseCase = DefaultGetTodosByDateUseCase(repository: TodoRepositoryImpl()),
        loadAllTodosUseCase: LoadAllTodosUseCase = DefaultLoadAllTodosUseCase(repository: TodoRepositoryImpl()),
        moveTodoUseCase: MoveTodoUseCase = DefaultMoveTodoUseCase(repository: TodoRepositoryImpl()),
        holidayUseCase: HolidayUseCase? = nil
    ) {
        self.addTodoUseCase = addTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.updateTodoUseCase = updateTodoUseCase
        self.getTodosByDateUseCase = getTodosByDateUseCase
        self.loadAllTodosUseCase = loadAllTodosUseCase
        self.moveTodoUseCase = moveTodoUseCase
        self.holidayUseCase = holidayUseCase

        setupNotificationObserver()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadAllTodos()
            self.generateCalendarDays(for: self.currentMonth)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// 월을 변경합니다.
    func changeMonth(by value: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            DispatchQueue.main.async {
                self.currentMonth = newDate
                self.generateCalendarDays(for: newDate)
            }
        }
    }

    /// 모든 Todo를 로드하여 todosByDate에 저장합니다.
    func loadAllTodos() {
        do {
            NSUbiquitousKeyValueStore.default.synchronize()
        } catch {
            print("⚠️ [CalendarViewModel] iCloud 동기화 실패: \(error.localizedDescription)")
        }

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

    /// 특정 날짜의 Todo 목록을 반환합니다.
    /// 기간별 일정 + 반복 가상 인스턴스 + 단일 일정을 결합합니다.
    func todos(for date: Date) -> [TodoItem] {
        let key = date.toDateString()
        let todosForDate = todosByDate[key] ?? []

        // 해당 날짜의 단일 날짜 일정들만 필터링 (기간별 일정 및 반복 원본 제외)
        let singleDayTodos = todosForDate.filter { !$0.isPeriodEvent && !$0.isRecurringEvent }

        // 단일 날짜 일정을 시간순으로 정렬
        let sortedSingleDayTodos = singleDayTodos.sorted { todo1, todo2 in
            if let time1 = todo1.scheduledTime, let time2 = todo2.scheduledTime {
                return time1 < time2
            }
            if todo1.scheduledTime != nil && todo2.scheduledTime == nil { return true }
            if todo1.scheduledTime == nil && todo2.scheduledTime != nil { return false }
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

    /// 공휴일 이름을 반환합니다.
    func holidayName(for date: Date) -> String? {
        return holidayUseCase?.holidayName(for: date)
    }

    /// 인접한 월의 공휴일을 미리 로드합니다.
    func preloadHolidays(baseDate: Date) {
        holidayUseCase?.preloadAdjacentMonths(baseDate: baseDate, completion: nil)
    }

    /// 달력의 날짜 데이터를 생성합니다.
    func generateCalendarDays(for date: Date) {
        let generateBlock = { [weak self] in
            guard let self = self else { return }
            let allTodos = self.loadAllTodosUseCase.execute()

            self.weeks = CalendarDayGenerator.generateWeeks(
                for: date,
                todos: allTodos,
                holidayNameProvider: { [weak self] date in
                    self?.holidayName(for: date)
                }
            )

            self.dates = CalendarDayGenerator.generate(for: date, todos: allTodos)
        }

        if Thread.isMainThread {
            generateBlock()
        } else {
            DispatchQueue.main.async(execute: generateBlock)
        }
    }

    /// Todo를 추가합니다.
    func addTodo(for date: Date, text: String, colorName: String) {
        let newTodo = TodoItem(
            text: text,
            isRepeating: isRepeating,
            date: date.toDateString(),
            colorName: colorName
        )

        addTodoUseCase.execute(todo: newTodo)
        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }

    /// iOS 버전과의 호환성을 위한 Todo 추가 메서드
    func addTodo() {
        guard let date = selectedDate, !todoText.isEmpty else { return }
        let hasRecurrence = selectedRecurrenceInfo != nil
        let newTodo = TodoItem(
            text: todoText,
            isRepeating: hasRecurrence || isRepeating,
            date: date.toDateString(),
            colorName: selectedColorName,
            scheduledTime: selectedScheduledTime,
            reminderMinutesBefore: selectedReminderMinutesBefore,
            recurrenceInfo: selectedRecurrenceInfo
        )
        addTodoUseCase.execute(todo: newTodo)
        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }

    /// 기간별 일정을 추가합니다.
    func addPeriodTodo() {
        guard let startDate = selectedStartDate,
              let endDate = selectedEndDate,
              !todoText.isEmpty else { return }

        let newTodo = TodoItem(
            text: todoText,
            isRepeating: isRepeating,
            startDate: startDate,
            endDate: endDate,
            colorName: selectedColorName,
            scheduledTime: selectedScheduledTime,
            reminderMinutesBefore: selectedReminderMinutesBefore
        )
        addTodoUseCase.execute(todo: newTodo)
        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }

    /// Todo를 삭제합니다.
    func deleteTodo(todo: TodoItem) {
        deleteTodoUseCase.execute(todo: todo)
        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }

    /// iOS 버전과의 호환성을 위한 Todo 삭제 메서드
    func deleteTodo(_ todo: TodoItem) {
        deleteTodo(todo: todo)
    }

    // MARK: - Recurring Event CRUD

    /// 반복 일정을 삭제합니다.
    func deleteRecurringTodo(_ todo: TodoItem, occurrenceDate: Date, scope: RecurrenceEditScope) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: occurrenceDate)

        guard let original = findOriginalRecurringTodo(for: todo) else {
            deleteTodo(todo: todo)
            return
        }

        switch scope {
        case .thisOnly:
            let exception = RecurrenceException(originalDate: dateString, isDeleted: true, overriddenTodo: nil)
            var exceptions = original.recurrenceExceptions ?? []
            exceptions.append(exception)
            let updated = original.withExceptions(exceptions)
            updateTodoUseCase.execute(original: original, updated: updated)

        case .thisAndFuture:
            guard var info = original.recurrenceInfo else { return }
            let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: occurrenceDate)
            let endDateStr = previousDay.map { formatter.string(from: $0) }
            info = RecurrenceInfo(frequency: info.frequency, interval: info.interval, endDate: endDateStr, endAfterCount: nil, daysOfWeek: info.daysOfWeek, dayOfMonth: info.dayOfMonth)
            let updated = original.withRecurrenceInfo(info)
            updateTodoUseCase.execute(original: original, updated: updated)

        case .all:
            deleteTodoUseCase.execute(todo: original)
        }

        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }

    /// 반복 일정을 수정합니다.
    func updateRecurringTodo(original: TodoItem, updated: TodoItem, occurrenceDate: Date, scope: RecurrenceEditScope) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: occurrenceDate)

        guard let source = findOriginalRecurringTodo(for: original) else {
            updateTodoUseCase.execute(original: original, updated: updated)
            loadAllTodos()
            generateCalendarDays(for: currentMonth)
            return
        }

        switch scope {
        case .thisOnly:
            let exception = RecurrenceException(originalDate: dateString, isDeleted: false, overriddenTodo: updated)
            var exceptions = source.recurrenceExceptions ?? []
            exceptions.removeAll { $0.originalDate == dateString }
            exceptions.append(exception)
            let updatedSource = source.withExceptions(exceptions)
            updateTodoUseCase.execute(original: source, updated: updatedSource)

        case .thisAndFuture:
            guard var oldInfo = source.recurrenceInfo else { return }
            let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: occurrenceDate)
            let endDateStr = previousDay.map { formatter.string(from: $0) }
            oldInfo = RecurrenceInfo(frequency: oldInfo.frequency, interval: oldInfo.interval, endDate: endDateStr, endAfterCount: nil, daysOfWeek: oldInfo.daysOfWeek, dayOfMonth: oldInfo.dayOfMonth)
            let truncated = source.withRecurrenceInfo(oldInfo)
            updateTodoUseCase.execute(original: source, updated: truncated)

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
            updateTodoUseCase.execute(original: source, updated: updatedAll)
        }

        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }

    /// 가상 인스턴스로부터 원본 반복 일정을 찾습니다.
    private func findOriginalRecurringTodo(for todo: TodoItem) -> TodoItem? {
        return allRecurringTodos.first { $0.id == todo.id }
    }

    /// Todo를 업데이트합니다.
    func updateTodo(original: TodoItem, text: String, colorName: String, date: Date? = nil) {
        if original.isPeriodEvent, let startDate = original.startDateObject, let endDate = original.endDateObject {
            let updatedTodo = TodoItem(
                text: text,
                isRepeating: original.isRepeating,
                startDate: startDate,
                endDate: endDate,
                colorName: colorName
            )
            updateTodoUseCase.execute(original: original, updated: updatedTodo)
        } else {
            let targetDate = date ?? original.dateObject ?? Date()
            let dateString = targetDate.toDateString()
            let updated = TodoItem(
                text: text,
                isRepeating: original.isRepeating,
                date: dateString,
                colorName: colorName
            )
            updateTodoUseCase.execute(original: original, updated: updated)
        }

        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }

    /// iOS 버전과의 호환성을 위한 Todo 업데이트 메서드
    func updateTodo(original: TodoItem, updatedText: String, updatedColor: String, date: Date? = nil) {
        updateTodo(original: original, text: updatedText, colorName: updatedColor, date: date)
    }

    /// 기간별 일정을 수정합니다.
    func updatePeriodTodo(original: TodoItem, updatedText: String, updatedColor: String, startDate: Date, endDate: Date) {
        let updatedTodo = TodoItem(text: updatedText,
                                  isRepeating: isRepeating,
                                  startDate: startDate,
                                  endDate: endDate,
                                  colorName: updatedColor)
        updateTodoUseCase.execute(original: original, updated: updatedTodo)
        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }

    /// Todo를 다른 날짜로 이동합니다.
    func moveTodo(from oldDate: String, to newDate: String, todoText: String) {
        guard oldDate != newDate else { return }

        let allTodos = loadAllTodosUseCase.execute()
        if let todoToMove = allTodos.first(where: {
            !$0.isPeriodEvent && $0.date == oldDate && $0.text == todoText
        }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            if let newDateObject = formatter.date(from: newDate) {
                moveTodoUseCase.execute(todo: todoToMove, to: newDateObject)
                loadAllTodos()

                DispatchQueue.main.async {
                    self.generateCalendarDays(for: self.currentMonth)
                }
            }
        } else {
            print("❌ [CalendarViewModel] 이동할 Todo를 찾을 수 없습니다 (oldDate: \(oldDate), text: \(todoText))")
        }
    }

    /// Todo를 ID로 직접 이동합니다
    func moveTodoById(_ todoId: UUID, to newDate: Date) {
        let allTodos = loadAllTodosUseCase.execute()
        if let todoToMove = allTodos.first(where: { $0.id == todoId }) {
            guard !todoToMove.isPeriodEvent else {
                print("⚠️ [CalendarViewModel] 기간별 일정은 이동할 수 없습니다")
                return
            }

            moveTodoUseCase.execute(todo: todoToMove, to: newDate)
            loadAllTodos()

            DispatchQueue.main.async {
                self.generateCalendarDays(for: self.currentMonth)
            }
        } else {
            print("❌ [CalendarViewModel] 이동할 Todo를 찾을 수 없습니다 (id: \(todoId))")
        }
    }

    // MARK: - Private Methods

    /// 알림 옵저버를 설정합니다.
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(todosUpdated),
            name: CloudSyncManager.todosDidUpdateNotification,
            object: nil
        )
    }

    /// Todo 업데이트 알림을 처리합니다.
    @objc private func todosUpdated() {
        DispatchQueue.main.async {
            self.loadAllTodos()
            self.generateCalendarDays(for: self.currentMonth)
        }
    }
}
