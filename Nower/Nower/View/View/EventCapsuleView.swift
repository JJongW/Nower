//
//  EventCapsuleView.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI

/// 일정을 캡슐 형태로 표시하는 뷰
/// iOS 버전과 동일한 디자인을 SwiftUI로 구현합니다.
struct EventCapsuleView: View {
    let todo: TodoItem
    let isPeriodEvent: Bool
    let position: PeriodEventPosition?
    let onTap: () -> Void
    let onDragStarted: () -> Void // 드래그 시작 콜백
    
    private var backgroundColor: Color {
        AppColors.color(for: todo.colorName)
    }
    
    private var textColor: Color {
        // 배경색에 대비되는 텍스트 색상 (간단한 구현)
        // 실제로는 더 정교한 휘도 계산이 필요하지만, 여기서는 기본적으로 흰색 사용
        Color.white
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isPeriodEvent, let position = position {
                // 기간별 일정
                periodEventView(position: position)
            } else {
                // 단일 날짜 일정
                singleDayEventView
            }
        }
        .frame(height: 20) // 모든 일정의 높이를 동일하게 고정 (macOS HIG - 더 큰 클릭 타겟)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onDrag {
            // 드래그 시작 시 콜백 호출
            onDragStarted()
            // 드래그 데이터 제공 (todo 텍스트를 전달)
            return NSItemProvider(object: todo.text as NSString)
        }
    }
    
    /// 단일 날짜 일정 뷰
    @ViewBuilder
    private var singleDayEventView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 일정 제목
            HStack(spacing: 4) {
                // 시간이 있으면 시간 표시
                if let time = todo.scheduledTime {
                    Text(time)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.9))
                }
                
                Text(todo.text)
                    .font(.system(size: 10))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if todo.isRecurringEvent {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 7))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(6)
    }
    
    /// 기간별 일정 뷰
    @ViewBuilder
    private func periodEventView(position: PeriodEventPosition) -> some View {
        Group {
            switch position {
            case .start:
                // 시작일: 텍스트 표시, 왼쪽만 둥글게
                // 오른쪽은 다음 셀과 연결되도록 확장
                HStack(spacing: 0) {
                    HStack(spacing: 4) {
                        // 시간이 있으면 시간 표시
                        if let time = todo.scheduledTime {
                            Text(time)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(textColor.opacity(0.9))
                        }
                        
                        Text(todo.text)
                            .font(.system(size: 10))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.leading, 6)
                    .padding(.vertical, 3)
                    Spacer(minLength: 0)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .background(backgroundColor)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 6,
                        bottomLeadingRadius: 6,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )
                .fixedSize(horizontal: false, vertical: true)
                // 오른쪽이 다음 셀과 연결되도록 확장
                
            case .middle:
                // 중간일: 빈 공간, 직각 (셀 경계를 넘어서 연결되도록)
                Rectangle()
                    .fill(backgroundColor)
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                    // 셀 경계를 넘어서 렌더링되도록 확장
                
            case .end:
                // 종료일: 빈 공간, 오른쪽만 둥글게
                // 왼쪽은 이전 셀과 연결되도록 확장
                Rectangle()
                    .fill(backgroundColor)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 6,
                            topTrailingRadius: 6
                        )
                    )
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                    // 왼쪽이 이전 셀과 연결되도록 확장
                
            case .single:
                // 단일 날짜: 모든 모서리 둥글게
                singleDayEventView
            }
        }
    }
}
