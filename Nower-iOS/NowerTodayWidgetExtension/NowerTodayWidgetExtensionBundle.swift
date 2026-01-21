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
        
        // 기존 템플릿 위젯들 (디버깅용으로 유지, 필요시 제거 가능)
        // NowerTodayWidgetExtension()
        // NowerTodayWidgetExtensionControl()
        // NowerTodayWidgetExtensionLiveActivity()
    }
}
