//
//  PopupBackgroundView.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI

/// 팝업 배경과 콘텐츠를 애니메이션과 함께 표시하는 뷰
/// 최신 Apple 스타일의 부드러운 spring 애니메이션 적용
struct PopupBackgroundView<Content: View>: View {
    @Binding var isPresented: Bool
    let content: () -> Content
    
    var body: some View {
        ZStack {
            // 반투명 배경 (페이드 인/아웃)
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
                .opacity(isPresented ? 1.0 : 0.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPresented)
            
            // 콘텐츠 (스케일 + 페이드 애니메이션)
            content()
                .scaleEffect(isPresented ? 1.0 : 0.9)
                .opacity(isPresented ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isPresented)
        }
    }
}
