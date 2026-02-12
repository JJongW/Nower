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
            
            // 윈도우 동작 설정 섹션
            GroupBox("윈도우 동작") {
                VStack(spacing: 8) {
                    Toggle("좌측 상단 고정", isOn: $settingsManager.isPinToTopLeft)
                        .help("화면 좌측 상단에 고정되고 드래그로 이동할 수 없게 됩니다")

                    Toggle("항상 위에 표시", isOn: Binding(
                        get: { settingsManager.isAlwaysOnTop },
                        set: { newValue in
                            settingsManager.isAlwaysOnTop = newValue
                            if newValue && settingsManager.isDesktopMode {
                                settingsManager.isDesktopMode = false
                            }
                        }
                    ))
                        .help("다른 앱 위에 항상 표시됩니다")
                        .disabled(settingsManager.isDesktopMode)

                    Divider()

                    Toggle("배경화면 고정", isOn: Binding(
                        get: { settingsManager.isDesktopMode },
                        set: { newValue in
                            settingsManager.isDesktopMode = newValue
                            if newValue && settingsManager.isAlwaysOnTop {
                                settingsManager.isAlwaysOnTop = false
                            }
                        }
                    ))
                        .help("윈도우를 배경화면처럼 모든 창 뒤에 고정합니다")
                        .disabled(settingsManager.isAlwaysOnTop)
                }
                .padding(.vertical, 5)
            }

            // 도움말 텍스트
            if settingsManager.isPinToTopLeft {
                Text("좌측 상단 고정이 활성화되면 윈도우를 드래그로 이동할 수 없습니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if settingsManager.isDesktopMode {
                Text("배경화면 고정 모드에서는 윈도우가 모든 창 뒤에 고정됩니다. 모든 Space에서 표시됩니다.")
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
        .frame(width: 380, height: 280)
    }
}
