//
//  EventListView.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI

/// 선택된 날짜의 일정 리스트를 표시하는 뷰
/// iOS 버전과 동일한 기능을 macOS에 맞게 SwiftUI로 구현
struct EventListView: View {
    let selectedDate: Date
    @Binding var isPresented: Bool
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    
    @EnvironmentObject var viewModel: CalendarViewModel
    
    @State private var isShowingAddEvent = false
    @State private var selectedTodoForEdit: TodoItem? = nil
    @State private var isShowingEditPopup = false
    
    private var todos: [TodoItem] {
        viewModel.todos(for: selectedDate)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: selectedDate)
    }
    
    private var weekDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE."
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: selectedDate).uppercased()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더 영역
            HStack {
                // 날짜 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(weekDayString)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                // "Today" 또는 날짜 라벨
                Text(isToday ? "Today" : selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // 닫기 버튼
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // 일정 리스트
            if todos.isEmpty {
                // 일정이 없는 경우
                VStack(spacing: 16) {
                    Spacer()
                    Text("일정이 없습니다")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(todos.enumerated()), id: \.element.id) { index, todo in
                            EventListRowView(todo: todo)
                                .onTapGesture {
                                    // 일정 클릭 시 편집 팝업 표시
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedTodoForEdit = todo
                                        isShowingEditPopup = true
                                    }
                                }
                                .opacity(1.0)
                                .scaleEffect(1.0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.03),
                                    value: todos.count
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            
            // 추가 버튼
            Button(action: {
                isShowingAddEvent = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(AppColors.textHighlighted)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 500, height: 600)
        .background(AppColors.popupBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .overlay {
            // 편집 팝업 뷰
            if isShowingEditPopup, let todo = selectedTodoForEdit {
                PopupBackgroundView(isPresented: $isShowingEditPopup) {
                    EditTodoPopupView(
                        todo: todo,
                        date: selectedDate.toDateString(),
                        isPresented: $isShowingEditPopup,
                        showToast: $showToast,
                        toastMessage: $toastMessage
                    )
                    .environmentObject(viewModel)
                }
            }
        }
        .overlay {
            // 일정 추가 뷰
            if isShowingAddEvent {
                PopupBackgroundView(isPresented: $isShowingAddEvent) {
                    AddEventViewForDate(
                        initialDate: selectedDate,
                        selectedColor: Binding(
                            get: { viewModel.selectedColorName },
                            set: { viewModel.selectedColorName = $0 }
                        ),
                        isPopupVisible: $isShowingAddEvent,
                        onEventAdded: {
                            // 일정 추가 후 리스트 새로고침
                            viewModel.loadAllTodos()
                            viewModel.generateCalendarDays(for: viewModel.currentMonth)
                        }
                    )
                    .environmentObject(viewModel)
                }
            }
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}

/// 일정 리스트의 개별 행 뷰
struct EventListRowView: View {
    let todo: TodoItem
    
    private var backgroundColor: Color {
        AppColors.color(for: todo.colorName)
    }
    
    private var textColor: Color {
        AppColors.contrastingTextColor(for: backgroundColor)
    }
    
    private var subtitleText: String {
        if todo.isPeriodEvent, let startDate = todo.startDateObject, let endDate = todo.endDateObject {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            formatter.locale = Locale(identifier: "ko_KR")
            
            let startString = formatter.string(from: startDate)
            let endString = formatter.string(from: endDate)
            
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                return startString
            } else {
                return "\(startString) - \(endString)"
            }
        } else {
            return "일상"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text(subtitleText)
                    .font(.system(size: 12))
                    .foregroundColor(textColor.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Spacer()
        }
        .background(backgroundColor)
        .cornerRadius(12)
        .padding(.horizontal, 4)
    }
}
