//
//  SettingsView.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import SwiftUI

#if canImport(NowerCore)
import NowerCore
#endif

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var templates: [EventTemplate] = []
    @State private var appleCalendarEnabled = ExternalCalendarManager.shared.isAppleEnabled
    @State private var showPermissionAlert = false

    var body: some View {
        VStack(spacing: 0) {
            Text("Nower 설정")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            // 템플릿 섹션
            VStack(alignment: .leading, spacing: 8) {
                Text("이벤트 템플릿")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if templates.isEmpty {
                    Text("저장된 템플릿이 없습니다.\n일정 추가 창에서 '템플릿 저장'을 눌러 추가하세요.")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(templates) { template in
                                templateRow(template)
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }

            Divider()
                .padding(.top, 8)

            // 외부 캘린더 섹션
            VStack(alignment: .leading, spacing: 8) {
                Text("외부 캘린더")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Toggle(isOn: $appleCalendarEnabled) {
                    Text("Apple 캘린더 연동")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textPrimary)
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 16)
                .onChange(of: appleCalendarEnabled) { enabled in
                    handleAppleToggle(enabled)
                }

                Text("켜면 기기의 Apple 캘린더 일정을 Nower 달력에 함께 보여줘요. 읽기 전용이라 Nower에서 수정·삭제는 안 돼요.")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textFieldPlaceholder)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }

            Spacer()

            Divider()

            Button("닫기") {
                NSApplication.shared.keyWindow?.close()
            }
            .padding(.vertical, 12)
        }
        .frame(width: 380, height: 440)
        .onAppear { loadTemplates() }
        .alert("캘린더 접근이 필요해요", isPresented: $showPermissionAlert) {
            Button("시스템 설정 열기") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("시스템 설정 > 개인정보 보호 및 보안 > 캘린더에서 Nower를 허용하면 일정을 함께 볼 수 있어요.")
        }
    }

    /// Apple 캘린더 연동 토글 처리. 켤 때 권한을 요청하고, 거부되면 토글을 되돌린다.
    private func handleAppleToggle(_ enabled: Bool) {
        if enabled {
            Task { @MainActor in
                let granted = await ExternalCalendarManager.shared.requestAppleAccess()
                if granted {
                    ExternalCalendarManager.shared.setAppleEnabled(true)
                } else {
                    appleCalendarEnabled = false
                    showPermissionAlert = true
                }
            }
        } else {
            ExternalCalendarManager.shared.setAppleEnabled(false)
        }
    }

    private func templateRow(_ template: EventTemplate) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(AppColors.color(for: template.colorName))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textPrimary)
                if template.name != template.title {
                    Text(template.title)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                }
            }

            Spacer()

            if let rule = template.recurrenceRule {
                Text(rule.displayString)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textFieldPlaceholder)
            }

            Button(action: { deleteTemplate(template) }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.coralred)
            }
            .buttonStyle(.borderless)
            .help("템플릿 삭제")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func loadTemplates() {
        #if canImport(NowerCore)
        if case .success(let all) = DependencyContainer.shared.fetchTemplatesUseCase.executeAll() {
            templates = all
        }
        #endif
    }

    private func deleteTemplate(_ template: EventTemplate) {
        #if canImport(NowerCore)
        _ = DependencyContainer.shared.deleteTemplateUseCase.execute(template)
        loadTemplates()
        #endif
    }
}
