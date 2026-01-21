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
            
            // 기본 설정 섹션
            GroupBox("기본 설정") {
                VStack(spacing: 10) {
                    HStack {
                        Text("투명도:")
                        Slider(value: $settingsManager.opacity, in: 0.1...1.0, step: 0.1)
                        Text("\(Int(settingsManager.opacity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("배경 색상:")
                        Spacer()
                        ColorPicker("", selection: $settingsManager.backgroundColor, supportsOpacity: false)
                            .labelsHidden()
                    }
                }
                .padding(.vertical, 5)
            }
            
            // 윈도우 동작 설정 섹션
            GroupBox("윈도우 동작") {
                VStack(spacing: 8) {
                    Toggle("좌측 상단 고정", isOn: $settingsManager.isPinToTopLeft)
                        .help("화면 좌측 상단에 고정되고 드래그로 이동할 수 없게 됩니다")
                    
                    Toggle("항상 위에 표시", isOn: $settingsManager.isAlwaysOnTop)
                        .help("다른 앱 위에 항상 표시됩니다")
                }
                .padding(.vertical, 5)
            }
            
            // 도움말 텍스트
            if settingsManager.isPinToTopLeft {
                Text("🔒 좌측 상단 고정이 활성화되면 윈도우를 드래그로 이동할 수 없습니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button("닫기") {
                NSApplication.shared.keyWindow?.close()
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 380, height: 320)
        .onReceive(settingsManager.$opacity) { _ in
            NotificationCenter.default.post(name: .init("SettingsChanged"), object: nil)
        }
        .onReceive(settingsManager.$backgroundColor) { _ in
            NotificationCenter.default.post(name: .init("SettingsChanged"), object: nil)
        }
    }
}
