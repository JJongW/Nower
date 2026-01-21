//
//  ContentGridView.swift
//  Nower
//
//  Created by 신종원 on 3/16/25.
//  Updated for week-based calendar on 5/12/25.
//

import Foundation
import SwiftUI

struct CalendarGridView: View {
    @EnvironmentObject var viewModel: CalendarViewModel

    @State private var selectedDate: String? = nil
    @State private var selectedTodo: TodoItem? = nil
    @State private var isShowingEditPopup = false
    @State private var isShowingEventList = false // 일정 리스트 뷰 표시 여부
    @State private var eventListDate: Date? = nil // 일정 리스트에 표시할 날짜
    @State private var draggedTodo: TodoItem? = nil // 드래그 중인 일정
    @State private var draggedTodoSourceDate: String? = nil // 드래그 중인 일정의 원본 날짜

    @Binding var toastMessage: String
    @Binding var showToast: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 주별로 달력 표시 (iOS 버전과 동일) - 모든 주 표시
                if viewModel.weeks.isEmpty {
                    // 데이터가 로드되지 않은 경우
                    Text("달력을 불러오는 중...")
                        .foregroundColor(AppColors.textPrimary)
                        .padding()
                } else {
                    ForEach(Array(viewModel.weeks.enumerated()), id: \.offset) { weekIndex, week in
                        WeekView(
                            weekDays: week,
                            onDaySelected: { dateString in
                                // 날짜 클릭 시 일정 리스트 뷰 표시
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                if let date = formatter.date(from: dateString) {
                                    eventListDate = date
                                    isShowingEventList = true
                                }
                            },
                            onTodoSelected: { todo, dateString in
                                selectedTodo = todo
                                selectedDate = dateString
                                isShowingEditPopup = true
                            },
                            onTodoDragStarted: { todo, sourceDate in
                                draggedTodo = todo
                                draggedTodoSourceDate = sourceDate
                            },
                            onTodoDropped: { targetDate in
                                handleTodoDrop(targetDate: targetDate)
                            }
                        )
                        .environmentObject(viewModel)
                        .frame(minHeight: 100) // 각 주의 최소 높이 설정
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(maxHeight: .infinity)
        .overlay {
            // 편집 팝업 뷰
            if isShowingEditPopup, let todo = selectedTodo, let date = selectedDate {
                PopupBackgroundView(isPresented: $isShowingEditPopup) {
                    EditTodoPopupView(
                        todo: todo,
                        date: date,
                        isPresented: $isShowingEditPopup,
                        showToast: $showToast,
                        toastMessage: $toastMessage
                    )
                    .environmentObject(viewModel)
                }
            }
            
            // 일정 리스트 뷰
            if isShowingEventList, let date = eventListDate {
                PopupBackgroundView(isPresented: $isShowingEventList) {
                    EventListView(
                        selectedDate: date,
                        isPresented: $isShowingEventList,
                        showToast: $showToast,
                        toastMessage: $toastMessage
                    )
                    .environmentObject(viewModel)
                }
            }
        }
    }

    /// 일정 드롭 처리
    private func handleTodoDrop(targetDate: String) {
        guard let draggedTodo = draggedTodo,
              let sourceDate = draggedTodoSourceDate,
              sourceDate != targetDate else {
            // 드래그 중인 일정이 없거나 같은 날짜로 드롭한 경우
            self.draggedTodo = nil
            self.draggedTodoSourceDate = nil
            return
        }
        
        // 기간별 일정인 경우 이동 불가 (단일 일정만 이동 가능)
        if draggedTodo.isPeriodEvent {
            show(message: "⚠️ 기간별 일정은 이동할 수 없습니다.")
            self.draggedTodo = nil
            self.draggedTodoSourceDate = nil
            return
        }
        
        // 일정 이동 실행 (ID를 사용하여 더 안전하게)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let targetDateObject = formatter.date(from: targetDate) {
            viewModel.moveTodoById(draggedTodo.id, to: targetDateObject)
            show(message: "✅ 일정이 이동되었습니다.")
        } else {
            show(message: "❌ 날짜 형식 오류")
        }
        
        // 드래그 상태 초기화
        self.draggedTodo = nil
        self.draggedTodoSourceDate = nil
    }

    func show(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

