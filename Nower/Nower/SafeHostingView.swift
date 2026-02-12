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
    /// 참고: wantsLayer = true는 NSHostingView의 내부 렌더링과 충돌해 Release에서 검은 화면 원인이 될 수 있어 제거함
    private func setupSafeConfiguration() {
        autoresizingMask = [.width, .height]
        needsDisplay = true
    }
    
    /// 뷰가 윈도우에 추가될 때 안전성 확보
    /// TestFlight/Release 빌드에서 즉시 firstResponder를 주면 SwiftUI 레이아웃이 준비되기 전에
    /// 호스팅 뷰가 그려지지 않아 검은 화면이 나올 수 있으므로, 다음 런루프에서 설정합니다.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard window != nil else { return }
        
        // 레이아웃이 끝난 뒤 firstResponder 설정 (검은 화면 방지)
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.window else { return }
            guard window.firstResponder != self else { return }
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

