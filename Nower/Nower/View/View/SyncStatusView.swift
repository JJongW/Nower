//
//  SyncStatusView.swift
//  Nower (macOS)
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI
#if canImport(NowerCore)
import NowerCore
#endif

struct SyncStatusView: View {
    @ObservedObject var viewModel: SyncStatusViewModel
    @State private var rotationDegrees: Double = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: { viewModel.handleTap() }) {
                ZStack {
                    Image(systemName: viewModel.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(viewModel.iconColor)
                        .rotationEffect(.degrees(viewModel.isAnimating ? rotationDegrees : 0))
                        .frame(width: 28, height: 28)

                    // Conflict badge (Task #5)
                    if viewModel.conflictCount > 0 {
                        Text("\(viewModel.conflictCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(3)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                    }
                }
            }
            .buttonStyle(.borderless)
            .help(viewModel.stateDescription)
            .accessibilityLabel(viewModel.stateDescription)
            .opacity(viewModel.isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isVisible)
            .onChange(of: viewModel.isAnimating) { animating in
                if animating {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        rotationDegrees = 360
                    }
                } else {
                    rotationDegrees = 0
                }
            }
        }
        .overlay(
            Group {
                if viewModel.showLastSyncedToast, let text = viewModel.lastSyncedText {
                    Text(text)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.textFieldBackground)
                        .cornerRadius(6)
                        .shadow(radius: 4)
                        .transition(.opacity)
                        .offset(y: 32)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { viewModel.showLastSyncedToast = false }
                            }
                        }
                }
            },
            alignment: .top
        )
    }
}
