//
//  WeekView.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI

/// 한 주를 표시하는 뷰
/// iOS 버전과 동일하게 7개의 날짜를 가로로 배치하고, 각 날짜의 일정들을 표시합니다.
struct WeekView: View {
    let weekDays: [WeekDayInfo]
    let onDaySelected: (String) -> Void
    let onTodoSelected: (TodoItem, String) -> Void
    let onTodoDragStarted: (TodoItem, String) -> Void // 드래그 시작 콜백
    let onTodoDropped: (String) -> Void // 드롭 완료 콜백
    
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        // macOS HIG 준수: 주간 단위로 모든 일정을 직접 렌더링
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // 배경
                AppColors.background
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // 날짜 헤더 셀들 (날짜 표시만 담당)
                HStack(spacing: 0) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { index, dayInfo in
                        DayView(
                            dayInfo: dayInfo,
                            fixedEventAreaHeight: calculateEventAreaHeight(), // 주 내 최대 일정 개수에 따른 고정 높이 전달
                            onDaySelected: {
                                if !dayInfo.dateString.isEmpty {
                                    onDaySelected(dayInfo.dateString)
                                }
                            },
                            onTodoSelected: { todo in
                                onTodoSelected(todo, dayInfo.dateString)
                            },
                            onTodoDragStarted: { todo in
                                onTodoDragStarted(todo, dayInfo.dateString)
                            },
                            onTodoDropped: {
                                onTodoDropped(dayInfo.dateString)
                            }
                        )
                        .environmentObject(viewModel)
                        .frame(width: geometry.size.width / 7) // 각 셀을 균등하게 분할
                        .frame(height: geometry.size.height) // 주의 전체 높이에 맞춰 모든 셀의 높이를 동일하게 설정
                    }
                }
                
                // 모든 일정을 WeekView에서 직접 렌더링 (기간별 + 단일 일정)
                allEventsView(geometry: geometry)
            }
        }
        .frame(minHeight: calculateMinHeight()) // 주 내 최대 일정 개수에 따른 최소 높이 계산
    }
    
    /// 모든 일정을 WeekView에서 직접 렌더링 (기간별 + 단일 일정)
    /// 오버레이가 아닌 WeekView의 일부로 렌더링하여 셀 경계를 넘어서 하나의 연속된 바로 표시
    @ViewBuilder
    private func allEventsView(geometry: GeometryProxy) -> some View {
        let cellWidth = geometry.size.width / 7
        let eventHeight: CGFloat = 20 // macOS HIG: 일정 높이 20pt
        let eventSpacing: CGFloat = 4 // macOS HIG: 일정 간 간격 4pt
        let topPadding: CGFloat = 12 // macOS HIG: 상단 여백 12pt
        let dayLabelHeight: CGFloat = 14 // macOS HIG: dayLabel 높이 14pt
        let dayLabelToHolidaySpacing: CGFloat = 6 // macOS HIG: dayLabel과 holidayLabel 사이 간격 6pt
        let holidayLabelHeight: CGFloat = 12 // macOS HIG: holidayLabel 높이 12pt
        let holidayToEventSpacing: CGFloat = 6 // macOS HIG: holidayLabel과 eventStackView 사이 간격 6pt
        
        let hasHoliday = weekDays.contains { $0.holidayName != nil }
        let headerHeight = topPadding + dayLabelHeight + dayLabelToHolidaySpacing + (hasHoliday ? holidayLabelHeight : 0)
        let eventAreaStartY = headerHeight + holidayToEventSpacing
        
        // 주 내 모든 일정 수집 및 행 배치 계산
        let eventRows = calculateEventRows()
        
        // 각 행의 일정들을 렌더링
        ForEach(Array(eventRows.enumerated()), id: \.offset) { rowIndex, rowEvents in
            ForEach(rowEvents, id: \.id) { eventInfo in
                eventView(
                    eventInfo: eventInfo,
                    cellWidth: cellWidth,
                    eventHeight: eventHeight,
                    eventAreaStartY: eventAreaStartY,
                    eventSpacing: eventSpacing,
                    rowIndex: rowIndex
                )
            }
        }
    }
    
    /// 일정 행 배치 계산 (기간별 일정과 단일 일정을 함께 배치)
    private func calculateEventRows() -> [[(id: UUID, todo: TodoItem, startIndex: Int, endIndex: Int, isPeriod: Bool)]] {
        var rows: [[(id: UUID, todo: TodoItem, startIndex: Int, endIndex: Int, isPeriod: Bool)]] = []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // 기간별 일정 수집 (중복 제거)
        var periodEvents: [(id: UUID, todo: TodoItem, startIndex: Int, endIndex: Int)] = []
        for dayInfo in weekDays {
            for todo in dayInfo.todos where todo.isPeriodEvent {
                if periodEvents.contains(where: { $0.id == todo.id }) { continue }
                
                guard let startDate = todo.startDateObject,
                      let endDate = todo.endDateObject else { continue }
                
                var startIndex: Int? = nil
                var endIndex: Int? = nil
                
                for (index, day) in weekDays.enumerated() {
                    guard !day.dateString.isEmpty,
                          let dayDate = formatter.date(from: day.dateString) else { continue }
                    
                    if dayDate >= startDate && dayDate <= endDate {
                        if startIndex == nil { startIndex = index }
                        endIndex = index
                    }
                }
                
                if let startIdx = startIndex, let endIdx = endIndex {
                    periodEvents.append((id: todo.id, todo: todo, startIndex: startIdx, endIndex: endIdx))
                }
            }
        }
        
        // 단일 일정 수집
        var singleEvents: [(id: UUID, todo: TodoItem, dayIndex: Int)] = []
        for (dayIndex, dayInfo) in weekDays.enumerated() {
            for todo in dayInfo.todos where !todo.isPeriodEvent {
                singleEvents.append((id: todo.id, todo: todo, dayIndex: dayIndex))
            }
        }
        
        // 행 배치: 기간별 일정과 단일 일정을 겹치지 않게 배치
        var usedRows: Set<Int> = []
        
        // 기간별 일정 배치
        for periodEvent in periodEvents {
            var placed = false
            for rowIndex in 0..<10 { // 최대 10행
                if !usedRows.contains(rowIndex) {
                    rows.append([(id: periodEvent.id, todo: periodEvent.todo, startIndex: periodEvent.startIndex, endIndex: periodEvent.endIndex, isPeriod: true)])
                    usedRows.insert(rowIndex)
                    placed = true
                    break
                }
            }
            if !placed {
                rows.append([(id: periodEvent.id, todo: periodEvent.todo, startIndex: periodEvent.startIndex, endIndex: periodEvent.endIndex, isPeriod: true)])
            }
        }
        
        // 단일 일정 배치 (각 날짜별로 최대 2개)
        for singleEvent in singleEvents {
            let dayIndex = singleEvent.dayIndex
            var placed = false
            
            // 해당 날짜에 이미 배치된 일정 개수 확인
            var dayEventCount = 0
            for row in rows {
                for event in row {
                    if !event.isPeriod && (event.startIndex == dayIndex || event.endIndex == dayIndex) {
                        dayEventCount += 1
                    }
                }
            }
            
            if dayEventCount < 2 {
                // 기존 행에 추가 가능한지 확인
                for (rowIndex, row) in rows.enumerated() {
                    var canAdd = true
                    for event in row {
                        if event.isPeriod {
                            // 기간별 일정과 겹치는지 확인
                            if dayIndex >= event.startIndex && dayIndex <= event.endIndex {
                                canAdd = false
                                break
                            }
                        } else {
                            // 같은 날짜에 이미 2개가 있는지 확인
                            if event.startIndex == dayIndex {
                                var count = 1
                                for e in row where !e.isPeriod && e.startIndex == dayIndex {
                                    count += 1
                                }
                                if count >= 2 {
                                    canAdd = false
                                    break
                                }
                            }
                        }
                    }
                    
                    if canAdd {
                        var newRow = row
                        newRow.append((id: singleEvent.id, todo: singleEvent.todo, startIndex: dayIndex, endIndex: dayIndex, isPeriod: false))
                        rows[rowIndex] = newRow
                        placed = true
                        break
                    }
                }
                
                if !placed {
                    rows.append([(id: singleEvent.id, todo: singleEvent.todo, startIndex: dayIndex, endIndex: dayIndex, isPeriod: false)])
                }
            }
        }
        
        return rows
    }
    
    /// 개별 일정 뷰 렌더링
    @ViewBuilder
    private func eventView(
        eventInfo: (id: UUID, todo: TodoItem, startIndex: Int, endIndex: Int, isPeriod: Bool),
        cellWidth: CGFloat,
        eventHeight: CGFloat,
        eventAreaStartY: CGFloat,
        eventSpacing: CGFloat,
        rowIndex: Int
    ) -> some View {
        let startX = CGFloat(eventInfo.startIndex) * cellWidth
        let endX = CGFloat(eventInfo.endIndex + 1) * cellWidth
        let width = endX - startX
        let y = eventAreaStartY + CGFloat(rowIndex) * (eventHeight + eventSpacing) + eventHeight / 2
        
        if eventInfo.isPeriod {
            // 기간별 일정: 하나의 연속된 바로 표시
            Rectangle()
                .fill(AppColors.color(for: eventInfo.todo.colorName))
                .frame(width: width, height: eventHeight)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 6,
                        bottomLeadingRadius: 6,
                        bottomTrailingRadius: 6,
                        topTrailingRadius: 6
                    )
                )
                .overlay(
                    Text(eventInfo.todo.text)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.leading, 6)
                        .padding(.trailing, 6)
                )
                .position(x: startX + width / 2, y: y)
                .onTapGesture {
                    if let startDate = eventInfo.todo.startDateObject {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let dateString = formatter.string(from: startDate)
                        onTodoSelected(eventInfo.todo, dateString)
                    }
                }
        } else {
            // 단일 일정: 해당 날짜 셀 내에 표시
            EventCapsuleView(
                todo: eventInfo.todo,
                isPeriodEvent: false,
                position: nil,
                onTap: {
                    onTodoSelected(eventInfo.todo, weekDays[eventInfo.startIndex].dateString)
                },
                onDragStarted: {
                    onTodoDragStarted(eventInfo.todo, weekDays[eventInfo.startIndex].dateString)
                }
            )
            .frame(width: cellWidth - 8, height: eventHeight) // 셀 너비에서 패딩 제외
            .position(x: startX + cellWidth / 2, y: y)
        }
    }
    
    
    /// 주 내 최대 일정 개수를 기반으로 최소 높이를 계산
    /// macOS HIG 준수: macOS에 최적화된 간격 값 사용
    private func calculateMinHeight() -> CGFloat {
        // macOS HIG 준수: macOS에 최적화된 간격 값
        let topPadding: CGFloat = 12 // 상단 여백 12pt (macOS는 더 넓은 화면)
        let dayLabelHeight: CGFloat = 14 // dayLabel 높이 14pt (macOS는 더 큰 폰트)
        let dayLabelToHolidaySpacing: CGFloat = 6 // dayLabel과 holidayLabel 사이 간격 6pt (macOS는 더 넓은 간격)
        let holidayLabelHeight: CGFloat = 12 // holidayLabel 높이 12pt (macOS는 더 큰 폰트)
        let holidayToEventSpacing: CGFloat = 6 // holidayLabel과 eventStackView 사이 간격 6pt (macOS는 더 넓은 간격)
        let bottomPadding: CGFloat = 12 // 하단 여백 12pt (macOS는 더 넓은 화면)
        let eventHeight: CGFloat = 20 // 일정 높이 20pt (macOS는 더 큰 클릭 타겟)
        let eventSpacing: CGFloat = 4 // 일정 간 간격 4pt (macOS는 더 넓은 간격으로 가독성 향상)
        
        // 주 내 모든 날짜의 일정 개수 중 최대값 찾기
        var maxVisibleEventCount = 0
        var hasHoliday = false
        
        for dayInfo in weekDays {
            // 각 날짜에서 표시되는 일정 개수 계산 (기간별 일정 포함)
            // 최대 2개만 표시하고, 나머지는 "+N개"로 표시
            let visibleEventCount = min(dayInfo.todos.count, 2) // 최대 2개 표시
            maxVisibleEventCount = max(maxVisibleEventCount, visibleEventCount)
            
            // 공휴일이 있는 경우 확인
            if dayInfo.holidayName != nil {
                hasHoliday = true
            }
        }
        
        // macOS HIG 준수: macOS에 최적화된 높이 계산
        // topSpace = 12 + 14 + 6 + (holidayName != nil ? 12 : 0)
        let topSpace = topPadding + dayLabelHeight + dayLabelToHolidaySpacing + (hasHoliday ? holidayLabelHeight : 0)
        let eventStackTopOffset = holidayToEventSpacing // 6pt (macOS HIG)
        
        // 최소 1개의 일정을 표시할 수 있는 높이 계산 (일정이 없는 날짜도 최소 높이 보장)
        // 최대 2개 + "+N개" 라벨(1개) = 총 3개 높이 필요
        let minVisibleEventCount = max(maxVisibleEventCount, 1)
        // "+N개" 라벨을 위한 공간도 고려하여 최대 3개 높이 계산
        let actualEventCount = minVisibleEventCount >= 2 ? 3 : minVisibleEventCount // 2개 이상이면 "+N개" 라벨 포함하여 3개 높이
        
        // 일정 영역 높이 계산: 첫 번째 일정은 간격 없음, 나머지는 간격 포함
        let eventsHeight = CGFloat(actualEventCount) * eventHeight + CGFloat(max(0, actualEventCount - 1)) * eventSpacing
        
        // 전체 높이 = topSpace + eventStackTopOffset + eventsHeight + bottomPadding
        return topSpace + eventStackTopOffset + eventsHeight + bottomPadding
    }
    
    /// 일정 영역의 고정 높이를 계산 (주 내 최대 일정 개수 기준)
    /// macOS HIG 준수: macOS에 최적화된 간격 값 사용
    private func calculateEventAreaHeight() -> CGFloat {
        // macOS HIG 준수: macOS에 최적화된 간격 값
        let eventHeight: CGFloat = 20 // 일정 높이 20pt (macOS는 더 큰 클릭 타겟)
        let eventSpacing: CGFloat = 4 // 일정 간 간격 4pt (macOS는 더 넓은 간격으로 가독성 향상)
        
        // 주 내 모든 날짜의 일정 개수 중 최대값 찾기
        var maxVisibleEventCount = 0
        for dayInfo in weekDays {
            let visibleEventCount = min(dayInfo.todos.count, 2) // 최대 2개 표시
            maxVisibleEventCount = max(maxVisibleEventCount, visibleEventCount)
        }
        
        // 최소 1개의 일정을 표시할 수 있는 높이 계산 (일정이 없는 날짜도 최소 높이 보장)
        // 최대 2개 + "+N개" 라벨(1개) = 총 3개 높이 필요
        let minVisibleEventCount = max(maxVisibleEventCount, 1)
        // "+N개" 라벨을 위한 공간도 고려하여 최대 3개 높이 계산
        let actualEventCount = minVisibleEventCount >= 2 ? 3 : minVisibleEventCount // 2개 이상이면 "+N개" 라벨 포함하여 3개 높이
        
        // macOS HIG 준수: 첫 번째 일정은 간격 없음, 나머지는 간격 포함
        return CGFloat(actualEventCount) * eventHeight + CGFloat(max(0, actualEventCount - 1)) * eventSpacing
    }
}
