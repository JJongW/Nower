//
//  DayView.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI

/// 주 내의 단일 날짜를 표시하는 뷰
/// iOS 버전과 동일한 디자인을 SwiftUI로 구현합니다.
struct DayView: View {
    let dayInfo: WeekDayInfo
    let fixedEventAreaHeight: CGFloat? // 주 내 최대 일정 개수에 따른 고정 높이 (nil이면 동적 계산)
    let onDaySelected: () -> Void
    let onTodoSelected: (TodoItem) -> Void
    let onTodoDragStarted: (TodoItem) -> Void // 드래그 시작 콜백
    let onTodoDropped: () -> Void // 드롭 완료 콜백
    
    @EnvironmentObject var viewModel: CalendarViewModel
    
    // fixedEventAreaHeight가 nil인 경우를 위한 기본 초기화
    init(dayInfo: WeekDayInfo, fixedEventAreaHeight: CGFloat? = nil, onDaySelected: @escaping () -> Void, onTodoSelected: @escaping (TodoItem) -> Void, onTodoDragStarted: @escaping (TodoItem) -> Void, onTodoDropped: @escaping () -> Void) {
        self.dayInfo = dayInfo
        self.fixedEventAreaHeight = fixedEventAreaHeight
        self.onDaySelected = onDaySelected
        self.onTodoSelected = onTodoSelected
        self.onTodoDragStarted = onTodoDragStarted
        self.onTodoDropped = onTodoDropped
    }
    
    // iOS와 동일한 간격으로 최적화
    private let topPadding: CGFloat = 2 // 상단 여백 축소 (12 → 2)
    private let dayLabelHeight: CGFloat = 14 // dayLabel 높이 14pt
    private let dayLabelToHolidaySpacing: CGFloat = 2 // dayLabel과 holidayLabel 사이 간격 축소 (6 → 2)
    private let holidayLabelHeight: CGFloat = 8 // holidayLabel 높이 축소 (12 → 8)
    private let holidayToEventSpacing: CGFloat = 0 // holidayLabel과 eventStackView 사이 간격 제거
    private let periodEventTopOffset: CGFloat = 28 // 기간일정 시작 오프셋 (iOS와 동일)
    private let bottomPadding: CGFloat = 4 // 하단 여백 축소 (12 → 4)
    private let maxEventHeight: CGFloat = 18 // 일정 높이 (iOS와 동일)
    private let eventSpacing: CGFloat = 2 // 일정 간 간격 축소 (4 → 2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 날짜 표시 - iOS 스타일로 개선
            if let day = dayInfo.day {
                VStack(spacing: 0) {
                    // 상단 여백
                    Spacer()
                        .frame(height: topPadding)
                    
                    // 오늘 날짜 원형 배경
                    ZStack {
                        if dayInfo.isToday {
                            Circle()
                                .fill(AppColors.textHighlighted)
                                .frame(width: 24, height: 24)
                        }
                        
                        // dayLabel: 원형 배경 중앙에 배치
                        Text("\(day)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(dayLabelColor)
                            .frame(height: dayLabelHeight)
                    }
                    .frame(height: 24) // 원형 배경 높이
                    
                    // dayLabel과 holidayLabel 사이 간격
                    Spacer()
                        .frame(height: dayLabelToHolidaySpacing)
                    
                    // holidayLabel
                    if let holidayName = dayInfo.holidayName {
                        Text(holidayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.coralred)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(height: holidayLabelHeight)
                    } else {
                        Spacer()
                            .frame(height: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    onDaySelected()
                }
                
                // 일정 영역 공간 확보 (실제 일정은 WeekView에서 렌더링)
                Spacer()
                    .frame(height: fixedEventAreaHeight ?? 0)
                    .padding(.bottom, bottomPadding)
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        let result = handleDrop(providers, for: dayInfo.dateString)
                        if result {
                            onTodoDropped()
                        }
                        return result
                    }
            } else {
                // 빈 날짜
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(dayBackgroundColor)
    }
    
    /// 날짜 라벨 색상 (iOS 스타일)
    private var dayLabelColor: Color {
        if dayInfo.isToday {
            // 오늘 날짜는 원형 배경 위에 흰색 텍스트
            return Color.white
        } else if let holidayName = dayInfo.holidayName, !holidayName.isEmpty {
            return AppColors.coralred
        } else if dayInfo.isSunday {
            return AppColors.coralred
        } else if dayInfo.isSaturday {
            return AppColors.skyblue
        } else {
            return AppColors.textPrimary
        }
    }
    
    /// 날짜 배경색 (선택 상태)
    private var dayBackgroundColor: Color {
        if dayInfo.isSelected {
            return AppColors.todoBackground.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    
    /// 드롭 핸들러
    private func handleDrop(_ providers: [NSItemProvider], for targetDate: String) -> Bool {
        guard let provider = providers.first else {
            return false
        }
        
        // 드롭 이벤트를 처리하고 상위 뷰에 알림
        // 실제 이동 처리는 CalendarGridView에서 수행
        return true
    }
}

/// 기간별 일정에서의 위치를 나타내는 열거형
enum PeriodEventPosition {
    case start      // 시작일
    case middle     // 중간일
    case end        // 종료일
    case single     // 단일 날짜 (기간이 아닌 일정)
}
