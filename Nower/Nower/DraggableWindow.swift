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
        // 위치 잠금 상태에서 드래그 차단
        if isPositionLocked && event.type == .leftMouseDragged {
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
        } else {
            // 이동 가능 상태로 복원
            self.isMovable = true
            self.isMovableByWindowBackground = true
            
            NotificationCenter.default.removeObserver(
                self,
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )
        }
    }
    
    /// 항상 위에 표시 기능 설정
    /// - Parameter enabled: 항상 위에 표시 여부
    func setAlwaysOnTop(_ enabled: Bool) {
        if enabled {
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        } else if !isDesktopModeEnabled {
            level = originalLevel
        }
    }

    // MARK: - Desktop Mode (배경화면 고정)
    //
    // 상태 정의:
    //   일반 모드: level=.normal, 표준 collectionBehavior → Mission Control O, Show Desktop 무관
    //   고정 모드: level=desktopIconWindow, .transient → Mission Control X, Show Desktop(fn+F11) O
    //
    // 고정 모드에서는 레벨이 절대 변경되지 않는다.
    // 클릭 시 NSApp만 활성화하고, 창 레벨은 desktopIconWindow를 유지한다.

    private var isDesktopModeEnabled: Bool = false
    private var savedCollectionBehavior: NSWindow.CollectionBehavior = []

    /// 배경화면 고정 모드 전환
    func setDesktopMode(_ enabled: Bool) {
        isDesktopModeEnabled = enabled

        if enabled {
            savedCollectionBehavior = collectionBehavior
            // desktopIcon 레벨: fn+F11(Show Desktop)에서 보임, 일반 앱 창 아래에 위치
            // 이 레벨은 고정 모드 해제 전까지 절대 변경되지 않는다
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
            // .transient: Mission Control 미표시
            // .stationary: Space 전환 시 위치 고정
            // .canJoinAllSpaces 제외 → Mission Control에서 숨김
            collectionBehavior = [.stationary, .ignoresCycle, .transient]
            titlebarAppearsTransparent = true
            titleVisibility = .hidden
            styleMask.insert(.fullSizeContentView)
            isPositionLocked = true
            self.isMovable = false
            hidesOnDeactivate = false
            ignoresMouseEvents = false
            // isOpaque = true로 유지해야 SwiftUI 콘텐츠가 정상 렌더링됨
            isOpaque = true
            backgroundColor = NSColor.windowBackgroundColor
            hasShadow = false
            orderBack(nil)
        } else {
            level = .normal
            collectionBehavior = savedCollectionBehavior.isEmpty
                ? [.canJoinAllSpaces]
                : savedCollectionBehavior
            titlebarAppearsTransparent = false
            titleVisibility = .visible
            styleMask.remove(.fullSizeContentView)
            if !pinToTopLeftEnabled {
                isPositionLocked = false
                self.isMovable = true
            }
            hidesOnDeactivate = false
            ignoresMouseEvents = false
            isOpaque = true
            backgroundColor = NSColor.windowBackgroundColor
            hasShadow = true
            makeKeyAndOrderFront(nil)
        }
    }

    /// 창이 key가 될 때 호출
    override func becomeKey() {
        super.becomeKey()
        if isDesktopModeEnabled {
            // 고정 모드: 레벨 유지 (desktopIconWindow), NSApp만 활성화
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // 팝업 알림 핸들러 (NotificationCenter 구독 유지용)
    @objc private func onPopupOpened() {}
    @objc private func onPopupClosed() {}

    // 하위 호환용 — 기존 호출부 컴파일 오류 방지
    func suspendInactivityTimer() {}
    func resumeInactivityTimer() {}
    private func cancelInactivityTimer() {}

    /// 현재 고정 모드 여부
    var isActivatedInDesktopMode: Bool { isDesktopModeEnabled }
    
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
    /// 주의: isOpaque = false, backgroundColor = .clear 로 두면 메인 창에서 SwiftUI 콘텐츠가 아예 안 그려지는
    /// 현상이 발생할 수 있으므로, 기본은 불투명 + 창 배경색으로 두고, 배경화면 모드에서만 투명 처리함.
    private func setupDesktopWidgetCapabilities() {
        originalLevel = level

        // 메인 창은 불투명 + 시스템 창 배경 (콘텐츠가 그려지도록). 배경화면 고정 모드 시 setDesktopMode에서 투명 처리.
        isOpaque = true
        backgroundColor = NSColor.windowBackgroundColor

        hasShadow = true
        isMovableByWindowBackground = false

        NotificationCenter.default.addObserver(self, selector: #selector(onPopupOpened),
            name: .nowerPopupOpened, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPopupClosed),
            name: .nowerPopupClosed, object: nil)
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
        cancelInactivityTimer()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let nowerPopupOpened = Notification.Name("NowerPopupOpened")
    static let nowerPopupClosed = Notification.Name("NowerPopupClosed")
}
