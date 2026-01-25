//
//  NowerWidgetBundle.swift
//  NowerWidget
//
//  Created by 신종원 on 1/25/26.
//

import WidgetKit
import SwiftUI

@main
struct NowerWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 월 달력 위젯
        NowerCalendarWidget()
    }
}
