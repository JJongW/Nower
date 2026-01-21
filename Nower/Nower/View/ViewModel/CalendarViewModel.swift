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
        
        // 알림 옵저버는 즉시 설정 (안전함)
        setupNotificationObserver()
        
        // 데이터 로딩과 UI 업데이트는 메인 스레드에서 비동기로 처리
        // 초기화 시점에서 메인 스레드가 준비되지 않았을 수 있으므로 지연 실행
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
    /// - Parameter value: 변경할 월 수 (음수: 이전, 양수: 다음)
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
    /// iOS 버전과의 호환성을 위해 추가되었습니다.
    func loadAllTodos() {
        // 안전하게 동기화 수행 (에러 처리 추가)
        do {
            NSUbiquitousKeyValueStore.default.synchronize()
        } catch {
            print("⚠️ [CalendarViewModel] iCloud 동기화 실패: \(error.localizedDescription)")
        }
        
        todosByDate = [:]
        let allTodos = loadAllTodosUseCase.execute()
        for todo in allTodos {
            todosByDate[todo.date, default: []].append(todo)
        }
    }
    
    /// 특정 날짜의 Todo 목록을 반환합니다.
    /// 기간별 일정도 포함하여 반환합니다.
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 Todo 목록
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
    
    /// 공휴일 이름을 반환합니다.
    /// - Parameter date: 조회할 날짜
    /// - Returns: 공휴일 이름 (없으면 nil)
    func holidayName(for date: Date) -> String? {
        return holidayUseCase?.holidayName(for: date)
    }
    
    /// 인접한 월의 공휴일을 미리 로드합니다.
    /// - Parameter baseDate: 기준 날짜
    func preloadHolidays(baseDate: Date) {
        holidayUseCase?.preloadAdjacentMonths(baseDate: baseDate, completion: nil)
    }
    
    /// 달력의 날짜 데이터를 생성합니다.
    /// - Parameter date: 기준 날짜
    func generateCalendarDays(for date: Date) {
        // 이미 메인 스레드인지 확인
        let generateBlock = { [weak self] in
            guard let self = self else { return }
            let allTodos = self.loadAllTodosUseCase.execute()
            
            // 주별 달력 생성 (iOS 버전과 동일)
            self.weeks = CalendarDayGenerator.generateWeeks(
                for: date,
                todos: allTodos,
                holidayNameProvider: { [weak self] date in
                    self?.holidayName(for: date)
                }
            )
            
            // 하위 호환성을 위해 dates도 업데이트
            self.dates = CalendarDayGenerator.generate(for: date, todos: allTodos)
        }
        
        if Thread.isMainThread {
            generateBlock()
        } else {
            DispatchQueue.main.async(execute: generateBlock)
        }
    }
    
    /// Todo를 추가합니다.
    /// - Parameters:
    ///   - date: 추가할 날짜
    ///   - text: Todo 내용
    ///   - colorName: 색상 이름
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
        let newTodo = TodoItem(text: todoText, isRepeating: isRepeating, date: date.toDateString(), colorName: selectedColorName)
        addTodoUseCase.execute(todo: newTodo)
        loadAllTodos()
        generateCalendarDays(for: currentMonth)
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
                              colorName: selectedColorName)
        addTodoUseCase.execute(todo: newTodo)
        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }
    
    /// Todo를 삭제합니다.
    /// - Parameter todo: 삭제할 Todo
    func deleteTodo(todo: TodoItem) {
        deleteTodoUseCase.execute(todo: todo)
        loadAllTodos()
        generateCalendarDays(for: currentMonth)
    }
    
    /// iOS 버전과의 호환성을 위한 Todo 삭제 메서드
    func deleteTodo(_ todo: TodoItem) {
        deleteTodo(todo: todo)
    }
    
    /// Todo를 업데이트합니다.
    /// - Parameters:
    ///   - original: 원본 Todo
    ///   - text: 새로운 내용
    ///   - colorName: 새로운 색상
    ///   - date: 새로운 날짜 (선택적)
    func updateTodo(original: TodoItem, text: String, colorName: String, date: Date? = nil) {
        // 기간별 일정인 경우 기간 정보를 유지
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
            // 단일 날짜 일정인 경우
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
    /// - Parameters:
    ///   - original: 원본 Todo
    ///   - updatedText: 새로운 내용
    ///   - updatedColor: 새로운 색상
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
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
    /// - Parameters:
    ///   - oldDate: 기존 날짜 문자열
    ///   - newDate: 새로운 날짜 문자열
    ///   - todoText: 이동할 Todo 텍스트
    func moveTodo(from oldDate: String, to newDate: String, todoText: String) {
        guard oldDate != newDate else { return }
        
        let allTodos = loadAllTodosUseCase.execute()
        // 단일 날짜 일정만 찾기 (기간별 일정 제외)
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
    
    /// Todo를 ID로 직접 이동합니다 (더 안전한 방법)
    /// - Parameters:
    ///   - todoId: 이동할 Todo의 ID
    ///   - newDate: 새로운 날짜
    func moveTodoById(_ todoId: UUID, to newDate: Date) {
        let allTodos = loadAllTodosUseCase.execute()
        if let todoToMove = allTodos.first(where: { $0.id == todoId }) {
            // 기간별 일정은 이동 불가
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
