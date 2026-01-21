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
    
    // macOS HIG 준수: macOS에 최적화된 간격 값 사용 (더 넓은 화면과 마우스 인터랙션 고려)
    private let topPadding: CGFloat = 12 // 상단 여백 12pt (macOS는 더 넓은 화면)
    private let dayLabelHeight: CGFloat = 14 // dayLabel 높이 14pt (macOS는 더 큰 폰트)
    private let dayLabelToHolidaySpacing: CGFloat = 6 // dayLabel과 holidayLabel 사이 간격 6pt (macOS는 더 넓은 간격)
    private let holidayLabelHeight: CGFloat = 12 // holidayLabel 높이 12pt (macOS는 더 큰 폰트)
    private let holidayToEventSpacing: CGFloat = 6 // holidayLabel과 eventStackView 사이 간격 6pt (macOS는 더 넓은 간격)
    private let bottomPadding: CGFloat = 12 // 하단 여백 12pt (macOS는 더 넓은 화면)
    private let maxEventHeight: CGFloat = 20 // 일정 높이 20pt (macOS는 더 큰 클릭 타겟)
    private let eventSpacing: CGFloat = 4 // 일정 간 간격 4pt (macOS는 더 넓은 간격으로 가독성 향상)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 날짜 표시 - HIG 준수: 정확한 간격 적용
            if let day = dayInfo.day {
                VStack(spacing: 0) {
                    // 상단 여백 12pt (macOS HIG)
                    Spacer()
                        .frame(height: topPadding)
                    
                    // dayLabel: 높이 14pt (macOS는 더 큰 폰트)
                    Text("\(day)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(dayLabelColor)
                        .frame(height: dayLabelHeight)
                    
                    // dayLabel과 holidayLabel 사이 간격 6pt (macOS는 더 넓은 간격)
                    Spacer()
                        .frame(height: dayLabelToHolidaySpacing)
                    
                    // holidayLabel: 높이 12pt (macOS는 더 큰 폰트)
                    if let holidayName = dayInfo.holidayName {
                        Text(holidayName)
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.coralred)
                            .lineLimit(1)
                            .frame(height: holidayLabelHeight)
                    } else {
                        // 공휴일이 없어도 공간 유지 (높이 0)
                        Spacer()
                            .frame(height: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .onTapGesture {
                    onDaySelected()
                }
                
                // holidayLabel과 일정 영역 사이 간격 6pt (macOS HIG)
                // 일정은 WeekView에서 직접 렌더링되므로 여기서는 공간만 확보
                Spacer()
                    .frame(height: holidayToEventSpacing)
                
                // 일정 영역 공간 확보 (실제 일정은 WeekView에서 렌더링)
                Spacer()
                    .frame(height: fixedEventAreaHeight ?? 0)
                    .padding(.bottom, bottomPadding) // 하단 여백 12pt (macOS HIG)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // alignment를 top으로 설정하여 날짜가 항상 상단에 고정
        .background(dayBackgroundColor)
        // SwiftUI는 기본적으로 클리핑하지 않으므로 기간별 일정이 셀 경계를 넘어서 렌더링됨
    }
    
    /// 날짜 라벨 색상
    private var dayLabelColor: Color {
        if let holidayName = dayInfo.holidayName, !holidayName.isEmpty {
            return AppColors.coralred
        } else if dayInfo.isToday {
            return AppColors.textHighlighted
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
