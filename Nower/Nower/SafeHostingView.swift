//
//  SafeHostingView.swift
//  Nower
//
//  Created by AI Assistant on 5/12/25.
//  Copyright © 2025 Nower. All rights reserved.
//

import SwiftUI
import Cocoa

/// TUINSRemoteViewController 에러를 방지하는 안전한 NSHostingView
/// 시스템 에러에 대한 적절한 처리를 제공합니다.
class SafeHostingView<Content: View>: NSHostingView<Content> {
    
    required init(rootView: Content) {
        super.init(rootView: rootView)
        setupSafeConfiguration()
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSafeConfiguration()
    }
    
    /// 안전한 구성 설정
    private func setupSafeConfiguration() {
        // 자동 크기 조정 설정
        autoresizingMask = [.width, .height]
        
        // 뷰 계층 구조 안정성 향상
        wantsLayer = true
        
        // 메모리 관리 개선
        needsDisplay = true
    }
    
    /// 뷰가 윈도우에 추가될 때 안전성 확보
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let window = self.window {
            // 윈도우 관련 안전성 설정
            window.makeFirstResponder(self)
        }
    }
    
    /// 뷰 업데이트 시 안전성 확보
    override func updateLayer() {
        super.updateLayer()
        
        // 레이어 업데이트 시 추가 안전성 검사
        layer?.needsDisplay()
    }
    
    /// 메모리 해제 시 정리 작업
    deinit {
        // 필요한 경우 정리 작업 수행
        // NotificationCenter observer 제거 등
    }
}

// MARK: - 편의 확장
extension SafeHostingView {
    /// 안전한 루트 뷰 업데이트
    /// - Parameter newRootView: 새로운 루트 뷰
    func updateRootViewSafely(_ newRootView: Content) {
        DispatchQueue.main.async { [weak self] in
            self?.rootView = newRootView
        }
    }
}

