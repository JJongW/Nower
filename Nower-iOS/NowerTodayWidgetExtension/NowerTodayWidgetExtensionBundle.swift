//
//  NowerTodayWidgetExtensionBundle.swift
//  NowerTodayWidgetExtension
//
//  Created by 신종원 on 1/21/26.
//

import WidgetKit
import SwiftUI

@main
struct NowerTodayWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // 오늘의 일정 위젯
        NowerTodayWidget()
        // 월간 달력 위젯
        NowerMonthCalendarWidget()
        // 하루 밀도 Companion (Live Activity)
        if #available(iOS 16.1, *) {
            NowerLiveActivity()
        }
    }
}
