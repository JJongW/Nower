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
class CalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var dates: [CalendarDay] = []
    @Published var currentMonth: Date = Date()
    @Published var isAddingEvent: Bool = false
    @Published var selectedEventType: EventType = .normal
    
    // MARK: - UseCase Dependencies
    private let addTodoUseCase: AddTodoUseCase
    private let deleteTodoUseCase: DeleteTodoUseCase
    private let updateTodoUseCase: UpdateTodoUseCase
    private let getTodosByDateUseCase: GetTodosByDateUseCase
    private let loadAllTodosUseCase: LoadAllTodosUseCase
    private let moveTodoUseCase: MoveTodoUseCase
    
    // MARK: - Initialization
    init(
        addTodoUseCase: AddTodoUseCase = DefaultAddTodoUseCase(repository: TodoRepositoryImpl()),
        deleteTodoUseCase: DeleteTodoUseCase = DefaultDeleteTodoUseCase(repository: TodoRepositoryImpl()),
        updateTodoUseCase: UpdateTodoUseCase = DefaultUpdateTodoUseCase(repository: TodoRepositoryImpl()),
        getTodosByDateUseCase: GetTodosByDateUseCase = DefaultGetTodosByDateUseCase(repository: TodoRepositoryImpl()),
        loadAllTodosUseCase: LoadAllTodosUseCase = DefaultLoadAllTodosUseCase(repository: TodoRepositoryImpl()),
        moveTodoUseCase: MoveTodoUseCase = DefaultMoveTodoUseCase(repository: TodoRepositoryImpl())
    ) {
        self.addTodoUseCase = addTodoUseCase
        self.deleteTodoUseCase = deleteTodoUseCase
        self.updateTodoUseCase = updateTodoUseCase
        self.getTodosByDateUseCase = getTodosByDateUseCase
        self.loadAllTodosUseCase = loadAllTodosUseCase
        self.moveTodoUseCase = moveTodoUseCase
        
        setupNotificationObserver()
        generateCalendarDays(for: currentMonth)
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
    
    /// 달력의 날짜 데이터를 생성합니다.
    /// - Parameter date: 기준 날짜
    func generateCalendarDays(for date: Date) {
        DispatchQueue.main.async {
            let allTodos = self.loadAllTodosUseCase.execute()
            self.dates = CalendarDayGenerator.generate(for: date, todos: allTodos)
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
            isRepeating: false,
            date: date,
            colorName: colorName
        )
        
        addTodoUseCase.execute(todo: newTodo)
        generateCalendarDays(for: currentMonth)
    }
    
    /// Todo를 삭제합니다.
    /// - Parameter todo: 삭제할 Todo
    func deleteTodo(todo: TodoItem) {
        deleteTodoUseCase.execute(todo: todo)
        generateCalendarDays(for: currentMonth)
    }
    
    /// Todo를 업데이트합니다.
    /// - Parameters:
    ///   - original: 원본 Todo
    ///   - text: 새로운 내용
    ///   - colorName: 새로운 색상
    func updateTodo(original: TodoItem, text: String, colorName: String) {
        let updated = TodoItem(
            text: text,
            isRepeating: original.isRepeating,
            date: original.date,
            colorName: colorName
        )
        
        updateTodoUseCase.execute(original: original, updated: updated)
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
        if let todoToMove = allTodos.first(where: { $0.date == oldDate && $0.text == todoText }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            if let newDateObject = formatter.date(from: newDate) {
                moveTodoUseCase.execute(todo: todoToMove, to: newDateObject)
                
                DispatchQueue.main.async {
                    self.generateCalendarDays(for: self.currentMonth)
                }
            }
        } else {
            print("❌ [CalendarViewModel] 이동할 Todo를 찾을 수 없습니다")
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
            self.generateCalendarDays(for: self.currentMonth)
        }
    }
}
