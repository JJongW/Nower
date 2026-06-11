//
//  DesktopCalendarWindow.swift
//  Nower
//
//  Desktop wallpaper widget-style window: desktop level, not in Mission Control,
//  borderless, non-movable, non-resizable. Double-click opens Add Schedule window.
//

import AppKit

/// Notification posted when user double-clicks inside the calendar (open Add Schedule).
/// userInfo["initialDate"]: Date? (optional; nil = use today).
extension Notification.Name {
    static let desktopCalendarOpenAddSchedule = Notification.Name("DesktopCalendarOpenAddSchedule")
}

/// 윈도우 레벨 및 collectionBehavior 설명:
///
/// - **level**: CGWindowLevelForKey(.desktopWindow) + 1
///   배경화면과 동일한 레이어(데스크톱 위젯과 동등). +1로 아이콘 바로 위에 그려져 배경화면에 붙어 보임.
///
/// - **collectionBehavior**:
///   - .canJoinAllSpaces: 모든 Space에 표시되어 Space 전환 시에도 같은 위치에 고정.
///   - .stationary: (일부 문서에서) Space에 묶여 이동하지 않음. canJoinAllSpaces와 함께 쓸 때 동작은 OS가 조합해 처리.
///   - .ignoresCycle: Cmd+` 윈도우 순환에서 제외. 앱이 .accessory이면 Cmd+Tab에도 안 나옴.
///   - .transient: Mission Control(Exposé)에 표시되지 않음.
final class DesktopCalendarWindow: NSWindow {

    /// Double-click 시 Add Schedule 열기용 초기 날짜 (nil = 오늘). 윈도우에서 클릭 위치로 날짜를 알 수 없으면 nil.
    private var pendingAddScheduleInitialDate: Date?
    /// 초기 위치 설정은 한 번만 허용 (positionWindow 등에서 호출).
    private var hasAppliedInitialFrame = false

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }

    /// 데스크톱 위젯용 설정 적용 (레벨, collectionBehavior, 테두리/이동/리사이즈 방지).
    func configureAsDesktopWidget() {
        // 1) 데스크톱 아이콘 바로 위 — Show Desktop(핫코너/F11)서 드러나고 클릭 받음.
        //    desktopWindow보다 한 단계 위라야 아이콘 뒤로 깔리지 않음.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))

        // 2) Mission Control 제외는 낮은 레벨 + .accessory 정책이 처리.
        //    .stationary: Show Desktop/Space 전환 시 제자리. (.transient는 Show Desktop서 숨겨질 수 있어 제외)
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        // 3) 테두리 없음, 배경에 붙은 느낌
        styleMask = [.borderless]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // 4) 이동/리사이즈 방지 (AppKit 제어)
        isMovable = false
        isMovableByWindowBackground = false
        styleMask.remove(.resizable)
        isRestorable = false

        // 5) 마우스 이벤트는 받음 (더블클릭, 버튼 등). 창 밖은 막지 않으므로 Finder 아이콘 등은 그대로 클릭 가능.
        ignoresMouseEvents = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// 이동 방지: 초기 위치 설정 후에는 위치/크기 변경 무시.
    override func setFrameOrigin(_ point: NSPoint) {
        guard hasAppliedInitialFrame else {
            super.setFrameOrigin(point)
            return
        }
        return
    }

    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        if !hasAppliedInitialFrame {
            hasAppliedInitialFrame = true
            super.setFrame(frameRect, display: flag)
            return
        }
        super.setFrame(frame, display: flag)
    }

    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        if !hasAppliedInitialFrame {
            hasAppliedInitialFrame = true
            super.setFrame(frameRect, display: displayFlag, animate: animateFlag)
            return
        }
        super.setFrame(frame, display: displayFlag, animate: animateFlag)
    }

    /// 더블클릭 감지: NSEvent.clickCount 사용. 캘린더 영역 내 더블클릭 시 Add Schedule 열기.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown, event.clickCount == 2 {
            let loc = event.locationInWindow
            if let contentView = contentView, contentView.bounds.contains(contentView.convert(loc, from: nil)) {
                // 초기 날짜는 윈도우에서는 알 수 없음. ContentView에서 날짜 지정 시 notification userInfo로 전달 가능.
                pendingAddScheduleInitialDate = nil
                NotificationCenter.default.post(
                    name: .desktopCalendarOpenAddSchedule,
                    object: self,
                    userInfo: ["initialDate": pendingAddScheduleInitialDate as Any]
                )
                return
            }
        }
        super.sendEvent(event)
    }

    /// ContentView 등에서 특정 날짜로 Add Schedule 열 때 호출 (선택 사항).
    func openAddSchedule(initialDate: Date?) {
        pendingAddScheduleInitialDate = initialDate
        NotificationCenter.default.post(
            name: .desktopCalendarOpenAddSchedule,
            object: self,
            userInfo: ["initialDate": initialDate as Any]
        )
    }
}
