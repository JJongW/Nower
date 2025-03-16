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
        VStack {
            Text("달력 설정")
                .font(.headline)
                .padding()

            HStack {
                Text("투명도:")
                Slider(value: $settingsManager.opacity, in: 0.1...1.0, step: 0.1)
            }
            .padding()

            HStack {
                Text("배경 색상:")
                ColorPicker("", selection: $settingsManager.backgroundColor, supportsOpacity: false)
                    .labelsHidden()
            }
            .padding()

            Button("닫기") {
                NSApplication.shared.keyWindow?.close()
            }
            .padding()
        }
        .padding()
        .frame(width: 300, height: 220)
        .onReceive(settingsManager.$opacity) { _ in
            NotificationCenter.default.post(name: .init("SettingsChanged"), object: nil)
        }
        .onReceive(settingsManager.$backgroundColor) { _ in
            NotificationCenter.default.post(name: .init("SettingsChanged"), object: nil)
        }
    }
}
