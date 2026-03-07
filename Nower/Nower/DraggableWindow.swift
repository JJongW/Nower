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
    
    /// 타이틀바에서 마우스 드래그 이벤트를 차단 + 배경화면 모드 타이머 리셋
    override func sendEvent(_ event: NSEvent) {
        // 배경화면 모드에서 마우스/키보드 이벤트 시 타이머 리셋
        if isDesktopModeEnabled && isTemporarilyActivated {
            switch event.type {
            case .leftMouseDown, .rightMouseDown, .leftMouseUp, .rightMouseUp,
                 .mouseMoved, .leftMouseDragged, .rightMouseDragged,
                 .keyDown, .keyUp, .scrollWheel:
                resetInactivityTimer()
            default:
                break
            }
        }

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
            
            #if DEBUG
            print("🔒 [DraggableWindow] 위치 완전 잠금 - 타이틀바 드래그 차단")
            #endif
        } else {
            // 이동 가능 상태로 복원
            self.isMovable = true
            self.isMovableByWindowBackground = true
            
            NotificationCenter.default.removeObserver(
                self,
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )
            
            #if DEBUG
            print("🔓 [DraggableWindow] 위치 잠금 해제 - 이동 가능")
            #endif
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

    private var isDesktopModeEnabled: Bool = false
    private var savedCollectionBehavior: NSWindow.CollectionBehavior = []
    /// 배경화면 모드에서 일시적으로 활성화된 상태인지
    private var isTemporarilyActivated: Bool = false
    /// 팝업(일정 추가/편집 등) 상호작용 중 여부
    private var isInteractingWithPopup: Bool = false
    /// 비활성화 타이머 (일정 시간 반응 없으면 고정 상태로)
    private var inactivityTimer: Timer?
    /// 비활성화까지의 시간 (초)
    private let inactivityTimeout: TimeInterval = 30.0

    /// 배경화면 고정 모드 설정
    /// level을 .normal로 유지하여 AppKit이 becomeKey()를 자동 호출하도록 함
    /// 배경화면 느낌은 collectionBehavior + orderBack으로 구현
    func setDesktopMode(_ enabled: Bool) {
        isDesktopModeEnabled = enabled

        if enabled {
            savedCollectionBehavior = collectionBehavior
            // level은 .normal 유지 → AppKit이 클릭 시 자동으로 becomeKey() 호출
            collectionBehavior = [.transient, .ignoresCycle]
            titlebarAppearsTransparent = true
            titleVisibility = .hidden
            styleMask.insert(.fullSizeContentView)
            isPositionLocked = true
            self.isMovable = false
            hidesOnDeactivate = false
            ignoresMouseEvents = false
            isOpaque = false
            backgroundColor = NSColor.clear
            orderBack(nil)
            #if DEBUG
            print("🖥️ [DraggableWindow] 배경화면 고정 모드 활성화")
            #endif
        } else {
            cancelInactivityTimer()
            isTemporarilyActivated = false
            collectionBehavior = savedCollectionBehavior.isEmpty
                ? [.moveToActiveSpace]
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
            // 일반 모드로 복원: 불투명 + 창 배경 (콘텐츠가 보이도록)
            isOpaque = true
            backgroundColor = NSColor.windowBackgroundColor
            #if DEBUG
            print("🖥️ [DraggableWindow] 배경화면 고정 모드 비활성화")
            #endif
        }
    }

    // MARK: - 배경화면 모드 활성화/비활성화 (클릭 시 전환)

    /// 창이 활성화될 때 호출 (클릭 등으로 포커스 받음)
    override func becomeKey() {
        super.becomeKey()

        if isDesktopModeEnabled {
            activateFromDesktopMode()
        }
    }

    /// 창이 비활성화될 때 호출 (다른 앱으로 포커스 이동)
    override func resignKey() {
        super.resignKey()

        guard isDesktopModeEnabled && isTemporarilyActivated else { return }

        // 시트(Alert, confirmationDialog 등)나 팝업 상호작용 중이면 배경 전환 방지
        if !sheets.isEmpty || isInteractingWithPopup {
            resetInactivityTimer()
            return
        }
        deactivateToDesktopMode()
    }

    /// 배경화면 모드에서 일시적으로 활성화 (일정 추가 등 가능)
    private func activateFromDesktopMode() {
        isTemporarilyActivated = true

        // level은 이미 .normal — collectionBehavior만 조정
        collectionBehavior = [.ignoresCycle, .transient]

        // 시각적으로 활성화 상태 표시
        isOpaque = true
        backgroundColor = NSColor.windowBackgroundColor
        // 타이틀바 표시
        titlebarAppearsTransparent = false
        titleVisibility = .visible

        // 다른 앱 위로 올라오게 함
        orderFront(nil)

        // 비활성화 타이머 시작
        resetInactivityTimer()

        #if DEBUG
        print("✨ [DraggableWindow] 배경화면 모드 → 일시 활성화")
        #endif
    }

    /// 일시 활성화 상태에서 다시 배경화면 고정 상태로 복귀
    private func deactivateToDesktopMode() {
        cancelInactivityTimer()
        isTemporarilyActivated = false

        // level은 .normal 유지 — 다른 앱 창 뒤로 보냄
        collectionBehavior = [.transient, .ignoresCycle]

        // 투명하게 변경
        isOpaque = false
        backgroundColor = NSColor.clear
        // 타이틀바 숨김
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // 다른 앱 창 뒤로 보냄
        orderBack(nil)

        #if DEBUG
        print("🔙 [DraggableWindow] 일시 활성화 → 배경화면 모드 복귀")
        #endif
    }

    /// 팝업 열림 시 타이머 일시 중단
    func suspendInactivityTimer() {
        isInteractingWithPopup = true
        cancelInactivityTimer()
    }

    /// 팝업 닫힘 시 타이머 재개
    func resumeInactivityTimer() {
        isInteractingWithPopup = false
        guard isDesktopModeEnabled && isTemporarilyActivated else { return }
        resetInactivityTimer()
    }

    @objc private func onPopupOpened() { suspendInactivityTimer() }
    @objc private func onPopupClosed() { resumeInactivityTimer() }

    /// 비활성화 타이머 시작/리셋
    private func resetInactivityTimer() {
        cancelInactivityTimer()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleInactivityTimeout()
            }
        }
    }

    /// 비활성화 타이머 취소
    private func cancelInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }

    /// 비활성화 타임아웃 처리
    private func handleInactivityTimeout() {
        guard isDesktopModeEnabled && isTemporarilyActivated else { return }

        #if DEBUG
        print("⏱️ [DraggableWindow] 비활성화 타임아웃 - 배경화면 모드로 복귀")
        #endif

        deactivateToDesktopMode()
        // 포커스 해제
        resignKey()
    }

    /// 현재 배경화면 모드에서 일시 활성화 상태인지
    var isActivatedInDesktopMode: Bool {
        return isDesktopModeEnabled && isTemporarilyActivated
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
