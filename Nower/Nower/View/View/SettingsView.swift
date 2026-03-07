//
//  SettingsView.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        VStack(spacing: 15) {
            Text("Nower 설정")
                .font(.headline)
                .padding(.bottom, 10)

            Spacer()

            Button("닫기") {
                NSApplication.shared.keyWindow?.close()
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 380, height: 160)
    }
}
