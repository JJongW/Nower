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
        let eventHeight: CGFloat = 18 // iOS와 동일 (20 → 18)
        let eventSpacing: CGFloat = 2 // iOS와 동일 (4 → 2)
        let topPadding: CGFloat = 2 // iOS와 동일 (12 → 2)
        let dayLabelHeight: CGFloat = 14
        let dayLabelToHolidaySpacing: CGFloat = 2 // iOS와 동일 (6 → 2)
        let holidayLabelHeight: CGFloat = 8 // iOS와 동일 (12 → 8)
        let holidayToEventSpacing: CGFloat = 0 // iOS와 동일 (6 → 0)
        let periodEventTopOffset: CGFloat = 28 // iOS와 동일
        let maxVisiblePeriodEventRows: Int = 3 // 최대 표시 가능한 기간일정 행 수
        
        let hasHoliday = weekDays.contains { $0.holidayName != nil }
        let headerHeight = topPadding + 24 + dayLabelToHolidaySpacing + (hasHoliday ? holidayLabelHeight : 0) // 24는 원형 배경 높이
        let eventAreaStartY = periodEventTopOffset // iOS와 동일하게 고정 오프셋 사용
        
        // 주 내 모든 일정 수집 및 행 배치 계산
        let (eventRows, hiddenPeriodEventCount, hiddenSingleEventCounts) = calculateEventRows()
        
        // 표시 가능한 행까지만 렌더링
        let visibleRows = Array(eventRows.prefix(maxVisiblePeriodEventRows))
        
        // 각 행의 일정들을 렌더링
        ForEach(Array(visibleRows.enumerated()), id: \.offset) { rowIndex, rowEvents in
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
        
        // 기간별 일정 "+N개" 표시 (3행 이상일 때)
        if hiddenPeriodEventCount > 0 {
            let y = eventAreaStartY + CGFloat(visibleRows.count) * (eventHeight + eventSpacing) + eventHeight / 2
            Text("+\(hiddenPeriodEventCount)개")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.textFieldPlaceholder)
                .frame(width: cellWidth, height: eventHeight)
                .position(x: cellWidth / 2, y: y)
        }
        
        // 각 날짜별 단일 일정 "+N개" 표시
        // 계산을 미리 수행하여 배열로 만들기
        let moreEventLabels: [(dayIndex: Int, hiddenCount: Int)] = (0..<weekDays.count).compactMap { dayIndex in
            if let hiddenCount = hiddenSingleEventCounts[dayIndex], hiddenCount > 0 {
                return (dayIndex: dayIndex, hiddenCount: hiddenCount)
            }
            return nil
        }
        
        ForEach(moreEventLabels, id: \.dayIndex) { item in
            moreEventLabelView(
                dayIndex: item.dayIndex,
                hiddenCount: item.hiddenCount,
                cellWidth: cellWidth,
                eventHeight: eventHeight,
                eventAreaStartY: eventAreaStartY,
                eventSpacing: eventSpacing,
                visibleRows: visibleRows
            )
        }
    }
    
    /// 일정 행 배치 계산 (기간별 일정과 단일 일정을 함께 배치)
    /// Returns: (표시할 행들, 숨겨진 기간별 일정 개수, 각 날짜별 숨겨진 단일 일정 개수)
    private func calculateEventRows() -> (rows: [[(id: UUID, todo: TodoItem, startIndex: Int, endIndex: Int, isPeriod: Bool)]], hiddenPeriodCount: Int, hiddenSingleCounts: [Int: Int]) {
        var rows: [[(id: UUID, todo: TodoItem, startIndex: Int, endIndex: Int, isPeriod: Bool)]] = []
        let maxVisiblePeriodEventRows: Int = 3 // 최대 표시 가능한 기간일정 행 수
        let maxVisibleSingleEventsPerDay: Int = 2 // 각 날짜별 최대 표시 가능한 단일 일정 개수
        
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
        
        // 기간별 일정 배치 (최대 3행까지만)
        var periodEventIndex = 0
        for periodEvent in periodEvents {
            if periodEventIndex >= maxVisiblePeriodEventRows {
                break // 최대 3행까지만 배치
            }
            
            var placed = false
            for rowIndex in 0..<maxVisiblePeriodEventRows {
                if !usedRows.contains(rowIndex) {
                    rows.append([(id: periodEvent.id, todo: periodEvent.todo, startIndex: periodEvent.startIndex, endIndex: periodEvent.endIndex, isPeriod: true)])
                    usedRows.insert(rowIndex)
                    placed = true
                    periodEventIndex += 1
                    break
                }
            }
            if !placed && periodEventIndex < maxVisiblePeriodEventRows {
                rows.append([(id: periodEvent.id, todo: periodEvent.todo, startIndex: periodEvent.startIndex, endIndex: periodEvent.endIndex, isPeriod: true)])
                periodEventIndex += 1
            }
        }
        
        // 숨겨진 기간별 일정 개수
        let hiddenPeriodEventCount = max(0, periodEvents.count - maxVisiblePeriodEventRows)
        
        // 각 날짜별 단일 일정 개수 추적
        var dayEventCounts: [Int: Int] = [:]
        for dayIndex in 0..<7 {
            dayEventCounts[dayIndex] = 0
        }
        
        // 단일 일정 배치 (각 날짜별로 최대 2개)
        for singleEvent in singleEvents {
            let dayIndex = singleEvent.dayIndex
            let currentCount = dayEventCounts[dayIndex] ?? 0
            
            if currentCount < maxVisibleSingleEventsPerDay {
                // 기존 행에 추가 가능한지 확인
                var placed = false
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
                                if count >= maxVisibleSingleEventsPerDay {
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
                        dayEventCounts[dayIndex] = (dayEventCounts[dayIndex] ?? 0) + 1
                        placed = true
                        break
                    }
                }
                
                if !placed {
                    rows.append([(id: singleEvent.id, todo: singleEvent.todo, startIndex: dayIndex, endIndex: dayIndex, isPeriod: false)])
                    dayEventCounts[dayIndex] = (dayEventCounts[dayIndex] ?? 0) + 1
                }
            }
        }
        
        // 각 날짜별 숨겨진 단일 일정 개수 계산
        var hiddenSingleEventCounts: [Int: Int] = [:]
        for (dayIndex, dayInfo) in weekDays.enumerated() {
            let singleDayTodos = dayInfo.todos.filter { !$0.isPeriodEvent }
            let visibleCount = dayEventCounts[dayIndex] ?? 0
            let hiddenCount = max(0, singleDayTodos.count - visibleCount)
            if hiddenCount > 0 {
                hiddenSingleEventCounts[dayIndex] = hiddenCount
            }
        }
        
        return (rows, hiddenPeriodEventCount, hiddenSingleEventCounts)
    }
    
    /// "+N개" 라벨 뷰 생성
    private func moreEventLabelView(
        dayIndex: Int,
        hiddenCount: Int,
        cellWidth: CGFloat,
        eventHeight: CGFloat,
        eventAreaStartY: CGFloat,
        eventSpacing: CGFloat,
        visibleRows: [[(id: UUID, todo: TodoItem, startIndex: Int, endIndex: Int, isPeriod: Bool)]]
    ) -> some View {
        // 해당 날짜의 표시된 단일 일정 개수 확인 (기간별 일정이 차지하는 행 수 고려)
        var visibleSingleEventCount = 0
        var maxPeriodEventRow = -1
        
        // 기간별 일정이 해당 날짜에 차지하는 최대 행 인덱스 찾기
        for (rowIdx, row) in visibleRows.enumerated() {
            for event in row {
                if event.isPeriod && dayIndex >= event.startIndex && dayIndex <= event.endIndex {
                    maxPeriodEventRow = max(maxPeriodEventRow, rowIdx)
                }
            }
        }
        
        // 해당 날짜의 표시된 단일 일정 개수 계산
        for row in visibleRows {
            for event in row {
                if !event.isPeriod && event.startIndex == dayIndex {
                    visibleSingleEventCount += 1
                }
            }
        }
        
        // "+N개" 라벨 위치 계산 (기간별 일정 행 수 + 단일 일정 개수)
        let baseRowCount = maxPeriodEventRow + 1
        let y = eventAreaStartY + CGFloat(baseRowCount + visibleSingleEventCount) * (eventHeight + eventSpacing) + eventHeight / 2
        let x = CGFloat(dayIndex) * cellWidth + cellWidth / 2
        
        return Text("+\(hiddenCount)개")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(AppColors.textFieldPlaceholder)
            .frame(width: cellWidth - 8, height: eventHeight)
            .position(x: x, y: y)
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
    /// iOS와 동일한 간격 값 사용
    private func calculateMinHeight() -> CGFloat {
        // iOS와 동일한 간격 값
        let topPadding: CGFloat = 2
        let dayLabelHeight: CGFloat = 14
        let dayLabelToHolidaySpacing: CGFloat = 2
        let holidayLabelHeight: CGFloat = 8
        let periodEventTopOffset: CGFloat = 28
        let bottomPadding: CGFloat = 4
        let eventHeight: CGFloat = 18
        let eventSpacing: CGFloat = 2
        
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
        
        // iOS와 동일한 높이 계산
        // topSpace = 2 + 24 + 2 + (holidayName != nil ? 8 : 0) (24는 원형 배경 높이)
        let topSpace = topPadding + 24 + dayLabelToHolidaySpacing + (hasHoliday ? holidayLabelHeight : 0)
        let eventStackTopOffset = periodEventTopOffset // 28pt
        
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
    /// iOS와 동일한 간격 값 사용
    private func calculateEventAreaHeight() -> CGFloat {
        // iOS와 동일한 간격 값
        let eventHeight: CGFloat = 18
        let eventSpacing: CGFloat = 2
        
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
