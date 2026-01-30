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
    @Published var selectedReminderMinutesBefore: Int?  // minutes or nil

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
    }

    func loadAllTodos() {
        NSUbiquitousKeyValueStore.default.synchronize()

        todosByDate = [:]
        let allTodos = loadAllTodosUseCase.execute()
        for todo in allTodos {
            todosByDate[todo.date, default: []].append(todo)
        }
    }

    func todos(for date: Date) -> [TodoItem] {
        let key = date.toDateString()
        let todosForDate = todosByDate[key] ?? []
        
        // 해당 날짜의 단일 날짜 일정들만 필터링 (기간별 일정 제외)
        let singleDayTodos = todosForDate.filter { !$0.isPeriodEvent }
        
        // 모든 일정에서 기간별 일정을 찾되 중복 제거
        let allTodos = todosByDate.values.flatMap { $0 }
        let uniquePeriodTodos = Array(Set(allTodos.filter { todo in
            todo.isPeriodEvent && todo.includesDate(date)
        }))
        
        // 기간별 일정을 시작일 순으로 정렬
        let sortedPeriodTodos = uniquePeriodTodos.sorted { first, second in
            guard let firstStart = first.startDateObject,
                  let secondStart = second.startDateObject else { return false }
            return firstStart < secondStart
        }
        
        // 기간별 일정을 우선으로 반환
        return sortedPeriodTodos + singleDayTodos
    }

    func holidayName(for date: Date) -> String? {
        return holidayUseCase.holidayName(for: date)
    }

    func preloadHolidays(baseDate: Date) {
        holidayUseCase.preloadAdjacentMonths(baseDate: baseDate, completion: nil)
    }

    func addTodo() {
        guard let date = selectedDate, !todoText.isEmpty else { return }
        let newTodo = TodoItem(text: todoText, isRepeating: isRepeating, date: date.toDateString(), colorName: selectedColorName, scheduledTime: selectedScheduledTime, reminderMinutesBefore: selectedReminderMinutesBefore)
        addTodoUseCase.execute(todo: newTodo)
        LocalNotificationManager.shared.scheduleNotification(for: newTodo)
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
                              reminderMinutesBefore: selectedReminderMinutesBefore)
        addTodoUseCase.execute(todo: newTodo)
        LocalNotificationManager.shared.scheduleNotification(for: newTodo)
    }

    func deleteTodo(_ todo: TodoItem) {
        LocalNotificationManager.shared.cancelNotification(for: todo.id)
        deleteTodoUseCase.execute(todo: todo)
    }

    func updateTodo(original: TodoItem, updatedText: String, updatedColor: String, date: Date? = nil, scheduledTime: String? = nil, reminderMinutesBefore: Int? = nil) {
        let targetDate = date ?? original.dateObject ?? Date()
        let dateString = targetDate.toDateString()
        let updatedTodo = TodoItem(text: updatedText, isRepeating: isRepeating, date: dateString, colorName: updatedColor, scheduledTime: scheduledTime, reminderMinutesBefore: reminderMinutesBefore)
        LocalNotificationManager.shared.cancelNotification(for: original.id)
        updateTodoUseCase.execute(original: original, updated: updatedTodo)
        LocalNotificationManager.shared.scheduleNotification(for: updatedTodo)
    }
    
    /// 기간별 일정을 수정합니다.
    func updatePeriodTodo(original: TodoItem, updatedText: String, updatedColor: String, startDate: Date, endDate: Date, scheduledTime: String? = nil, reminderMinutesBefore: Int? = nil) {
        let updatedTodo = TodoItem(text: updatedText,
                                  isRepeating: isRepeating,
                                  startDate: startDate,
                                  endDate: endDate,
                                  colorName: updatedColor,
                                  scheduledTime: scheduledTime,
                                  reminderMinutesBefore: reminderMinutesBefore)
        LocalNotificationManager.shared.cancelNotification(for: original.id)
        updateTodoUseCase.execute(original: original, updated: updatedTodo)
        LocalNotificationManager.shared.scheduleNotification(for: updatedTodo)
    }

    func debugPrintICloudTodos() {
        #if DEBUG
        NSUbiquitousKeyValueStore.default.synchronize()
        print("🔍 [iCloud] todos 확인 시작")

        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: "SavedTodos") else {
            print("⚠️ iCloud 저장소에 데이터 없음")
            return
        }

        do {
            let items = try JSONDecoder().decode([TodoItem].self, from: data)
            print("✅ \(items.count)개의 TodoItem 디코딩 완료:")
            for (i, item) in items.enumerated() {
                print("🔸 [\(i)] \(item.text) | \(item.date) | \(item.colorName) | 반복: \(item.isRepeating)")
            }
        } catch {
            print("❌ 디코딩 실패:", error)
        }
        #endif
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
    }
    
    /// Todo 업데이트 알림을 처리합니다.
    @objc private func todosDidUpdate() {
        DispatchQueue.main.async {
            self.loadAllTodos()
        }
    }
}
