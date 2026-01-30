//
//  ConflictResolutionView.swift
//  Nower (macOS)
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI
#if canImport(NowerCore)
import NowerCore
#endif

struct ConflictResolutionView: View {
    @ObservedObject var viewModel: SyncStatusViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("일정 동기화 충돌")
                        .font(.title2).bold()
                        .foregroundColor(AppColors.textPrimary)

                    Text("이 기기와 다른 기기에서 같은 일정을 수정했습니다. 유지할 버전을 선택하세요.")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                }

                Spacer()

                Menu("일괄 처리") {
                    Button("모두 이 기기 버전 사용") {
                        viewModel.resolveAllConflicts(resolution: .keepLocal)
                    }
                    Button("모두 다른 기기 버전 사용") {
                        viewModel.resolveAllConflicts(resolution: .keepRemote)
                    }
                    Button("모두 복제하여 보관") {
                        viewModel.resolveAllConflicts(resolution: .keepBoth)
                    }
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Conflicts List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.syncState.conflicts) { conflict in
                        ConflictCardView(conflict: conflict) { resolution in
                            viewModel.resolveConflict(conflict, resolution: resolution)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .frame(width: 520, height: 440)
        .background(AppColors.popupBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
        .onChange(of: viewModel.syncState.conflicts.count) { count in
            if count == 0 {
                isPresented = false
            }
        }
    }
}

// MARK: - ConflictCardView

private struct ConflictCardView: View {
    let conflict: SyncConflict
    let onResolve: (ConflictResolution) -> Void

    private var titleDiffers: Bool {
        conflict.localTitle != conflict.remoteTitle
    }

    private var dateDiffers: Bool {
        conflict.localDate != conflict.remoteDate
    }

    private var colorDiffers: Bool {
        conflict.localColorName != conflict.remoteColorName
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 16) {
                // Local version
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("이 기기")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                    }

                    Text(conflict.localTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(2)
                        .background(titleDiffers ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(3)

                    Text(conflict.localDate)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                        .padding(2)
                        .background(dateDiffers ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(3)

                    // Color swatch (Task #4)
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.color(for: conflict.localColorName))
                            .frame(width: 14, height: 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(colorDiffers ? Color.blue : Color.clear, lineWidth: 1.5)
                            )
                        Text(conflict.localColorName)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textFieldPlaceholder)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(AppColors.textFieldPlaceholder.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 4)

                // Remote version
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("다른 기기")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                    }

                    Text(conflict.remoteTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(2)
                        .background(titleDiffers ? Color.orange.opacity(0.1) : Color.clear)
                        .cornerRadius(3)

                    Text(conflict.remoteDate)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textFieldPlaceholder)
                        .padding(2)
                        .background(dateDiffers ? Color.orange.opacity(0.1) : Color.clear)
                        .cornerRadius(3)

                    // Color swatch (Task #4)
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.color(for: conflict.remoteColorName))
                            .frame(width: 14, height: 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(colorDiffers ? Color.orange : Color.clear, lineWidth: 1.5)
                            )
                        Text(conflict.remoteColorName)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textFieldPlaceholder)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Resolution buttons (Task #3: improved terminology)
            HStack(spacing: 8) {
                Button("이 기기 버전 사용") { onResolve(.keepLocal) }
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                Button("다른 기기 버전 사용") { onResolve(.keepRemote) }
                    .buttonStyle(.borderless)
                    .foregroundColor(.orange)
                Button("복제하여 모두 보관") { onResolve(.keepBoth) }
                    .buttonStyle(.borderless)
            }
            .font(.system(size: 12, weight: .medium))
        }
        .padding(12)
        .background(AppColors.textFieldBackground)
        .cornerRadius(8)
    }
}
