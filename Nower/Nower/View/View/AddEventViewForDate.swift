//
//  AddEventViewForDate.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI

/// 특정 날짜에 일정을 추가하는 뷰
/// EventListView에서 사용하기 위한 래퍼 뷰
struct AddEventViewForDate: View {
    let initialDate: Date
    @Binding var selectedColor: String
    @Binding var isPopupVisible: Bool
    let onEventAdded: () -> Void
    
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var body: some View {
        AddEventView(
            initialDate: initialDate,
            selectedColor: $selectedColor,
            isPopupVisible: $isPopupVisible
        )
        .environmentObject(viewModel)
        .onChange(of: isPopupVisible) { newValue in
            if !newValue {
                // 팝업이 닫힐 때 일정이 추가되었는지 확인하고 콜백 호출
                onEventAdded()
            }
        }
    }
}
