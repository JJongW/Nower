//
//  DraggableWindow.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//  Enhanced for desktop widget functionality on 5/12/25.
//

import Cocoa

/// 드래그 가능한 윈도우에 고정 기능을 추가한 클래스
/// 좌측 상단 고정 시 이동 불가능하도록 제어합니다.
class DraggableWindow: NSWindow {
    
    // MARK: - Properties
    private var originalLevel: NSWindow.Level = .normal
    private var pinToTopLeftEnabled: Bool = false
    private var isPositionLocked: Bool = false // 위치 잠금 상태
    
    // MARK: - Initialization
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupDesktopWidgetCapabilities()
    }
    
    // MARK: - NSWindow Overrides
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
    
    // MARK: - Position Lock Override
    
    /// 위치 잠금 상태에서는 윈도우 이동을 완전히 방지합니다
    override func setFrameOrigin(_ point: NSPoint) {
        if isPositionLocked {
            // 위치가 잠겨있으면 이동하지 않음
            return
        }
        super.setFrameOrigin(point)
    }
    
    /// 프레임 변경을 가로채서 위치 잠금 시 이동 방지
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        if isPositionLocked {
            // 위치가 잠겨있으면 크기만 변경하고 위치는 유지
            let currentOrigin = frame.origin
            let newFrame = NSRect(origin: currentOrigin, size: frameRect.size)
            super.setFrame(newFrame, display: flag)
        } else {
            super.setFrame(frameRect, display: flag)
        }
    }
    
    /// 모든 프레임 변경을 가로채는 최종 방어선
    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        if isPositionLocked {
            // 위치가 잠겨있으면 크기만 변경하고 위치는 유지
            let currentOrigin = frame.origin
            let newFrame = NSRect(origin: currentOrigin, size: frameRect.size)
            super.setFrame(newFrame, display: displayFlag, animate: animateFlag)
        } else {
            super.setFrame(frameRect, display: displayFlag, animate: animateFlag)
        }
    }
    
    /// 윈도우가 이동 가능한지 여부를 결정
    override var isMovable: Bool {
        get {
            return !isPositionLocked
        }
        set {
            if !isPositionLocked {
                super.isMovable = newValue
            }
        }
    }
    
    /// 윈도우가 이동될 수 있는지 여부 (macOS 10.6+)
    /// 배경 드래그로 창 이동을 항상 비활성화 (타이틀바에서만 이동 가능)
    override var isMovableByWindowBackground: Bool {
        get {
            return false // 배경 드래그로 창 이동 항상 비활성화
        }
        set {
            // 설정을 무시하고 항상 false로 유지
            super.isMovableByWindowBackground = false
        }
    }
    
    /// 타이틀바에서 마우스 드래그 이벤트를 차단
    override func sendEvent(_ event: NSEvent) {
        if isPositionLocked && event.type == .leftMouseDragged {
            // 위치가 잠겨있으면 드래그 이벤트를 무시
            return
        }
        super.sendEvent(event)
    }
    
    /// 마우스 다운 이벤트에서 드래그 시작을 차단
    override func mouseDown(with event: NSEvent) {
        if isPositionLocked {
            // 위치가 잠겨있으면 마우스 다운 이벤트를 무시
            return
        }
        super.mouseDown(with: event)
    }
    
    // MARK: - Position Lock Functionality
    
    /// 좌측 상단 고정 기능 설정
    /// - Parameter enabled: 고정 기능 활성화 여부
    func setPinToTopLeft(_ enabled: Bool) {
        pinToTopLeftEnabled = enabled
        isPositionLocked = enabled
        
        if enabled {
            moveToTopLeft()
            
            // 타이틀바 드래그도 완전히 차단
            self.isMovable = false
            self.isMovableByWindowBackground = false
            
            // 화면 해상도 변경 감지를 위한 옵저버 추가
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(screenConfigurationChanged),
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )
            
            print("🔒 [DraggableWindow] 위치 완전 잠금 - 타이틀바 드래그 차단")
        } else {
            // 이동 가능 상태로 복원
            self.isMovable = true
            self.isMovableByWindowBackground = true
            
            NotificationCenter.default.removeObserver(
                self,
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )
            
            print("🔓 [DraggableWindow] 위치 잠금 해제 - 이동 가능")
        }
    }
    
    /// 항상 위에 표시 기능 설정
    /// - Parameter enabled: 항상 위에 표시 여부
    func setAlwaysOnTop(_ enabled: Bool) {
        if enabled {
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        } else {
            level = originalLevel
        }
    }
    
    /// 윈도우를 화면 좌측 상단으로 이동
    private func moveToTopLeft() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let margin: CGFloat = 20 // 화면 가장자리로부터의 여백
        
        let newOrigin = NSPoint(
            x: screenFrame.minX + margin,
            y: screenFrame.maxY - frame.height - margin
        )
        
        // 위치 잠금 상태를 일시적으로 해제하여 이동 허용
        let wasLocked = isPositionLocked
        isPositionLocked = false
        setFrameOrigin(newOrigin)
        isPositionLocked = wasLocked
    }
    
    /// 화면 설정 변경 시 위치 재조정
    @objc private func screenConfigurationChanged() {
        if pinToTopLeftEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.moveToTopLeft()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 윈도우 초기 설정
    private func setupDesktopWidgetCapabilities() {
        originalLevel = level
        
        // 투명도 조절을 위한 설정
        isOpaque = false
        backgroundColor = NSColor.clear
        
        // 그림자 효과로 자연스러운 느낌 연출
        hasShadow = true
        
        // 배경 드래그로 창 이동 비활성화 (타이틀바에서만 이동 가능)
        isMovableByWindowBackground = false
    }
    
    // MARK: - Public Interface
    
    /// 현재 좌측 상단 고정 상태
    var isTopLeftPinned: Bool {
        return pinToTopLeftEnabled
    }
    
    /// 현재 위치 잠금 상태
    var isLocked: Bool {
        return isPositionLocked
    }
    
    /// 투명도 설정 (0.0 ~ 1.0)
    /// - Parameter opacity: 투명도 값
    func setWindowOpacity(_ opacity: CGFloat) {
        let clampedOpacity = max(0.1, min(1.0, opacity)) // 최소 0.1로 제한
        alphaValue = clampedOpacity
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
