//
//  AppDelegate.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//
import Cocoa
import SwiftUI
import ServiceManagement
// NOTE: Import NowerCore when package is linked
// import NowerCore

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: DraggableWindow?
    /// NSHostingController를 유지하지 않으면 해제되어 창이 비어 보일 수 있음
    private var mainHostingController: NSHostingController<AnyView>?
    var settingsManager = SettingsManager()
    let appBundleID = "pr.jongwon.Nower"

    /// CalendarViewModel을 공유하기 위해 ContentView에서 사용하는 것과 동일한 인스턴스 유지
    private let sharedCalendarViewModel = CalendarViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // NowerCore 마이그레이션 실행
        // TODO: Uncomment when NowerCore package is linked
        // Task { @MainActor in
        //     DependencyContainer.shared.runMigrationIfNeeded()
        //     DependencyContainer.shared.startSyncListening()
        // }

        setupMainWindow()
        setupMenuBar()
        enableAutoLaunch()

        // 윈도우 설정 관련 알림 설정
        NotificationCenter.default.addObserver(self, selector: #selector(pinToTopLeftChanged), name: .init("PinToTopLeftChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(alwaysOnTopChanged), name: .init("AlwaysOnTopChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(desktopModeChanged), name: .init("DesktopModeChanged"), object: nil)
    }

    func setupMainWindow() {
        let windowSize = CGSize(width: 1024, height: 720)
        let windowFrame: NSRect
        
        if let screen = NSScreen.main {
            // 저장된 위치가 현재 화면 안에 들어오는지 검사 (다른 기기에서 옮겼을 때 화면 밖에 있으면 무시)
            let visibleFrame = screen.visibleFrame
            if let saved = loadWindowPosition(),
               visibleFrame.intersects(NSRect(origin: saved, size: windowSize)) {
                windowFrame = NSRect(origin: saved, size: windowSize)
            } else {
                // 저장 위치 없거나 화면 밖이면 항상 화면 중앙에 생성
                let x = visibleFrame.midX - windowSize.width / 2
                let y = visibleFrame.midY - windowSize.height / 2
                windowFrame = NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height)
            }
        } else {
            // NSScreen.main이 nil인 환경(드물음) 대비
            windowFrame = NSRect(x: 100, y: 100, width: windowSize.width, height: windowSize.height)
        }

        let window = DraggableWindow(
            contentRect: windowFrame,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Nower"
        window.isOpaque = true
        window.hasShadow = true
        window.backgroundColor = NSColor.windowBackgroundColor
        window.level = .normal
        // Mission Control(Control+↑)에서 다른 창을 가리거나 클릭이 안 되지 않도록 일반 창 동작만 사용 (.fullScreenAuxiliary 제거)
        window.collectionBehavior = [.moveToActiveSpace]
        window.ignoresMouseEvents = false
        // 윈도우 복원 비활성화 (restoreWindowWithIdentifier className=null 경고 및 복원 시 콘텐츠 안 그려지는 현상 방지)
        window.isRestorable = false
        
        // 배경 드래그로 창 이동 비활성화 (타이틀바에서만 이동 가능)
        window.isMovableByWindowBackground = false

        // 컨테이너 뷰 위에 호스팅 뷰 배치 (DraggableWindow에서 contentViewController 사용 시 프레임이 0이 되는 문제 회피)
        let contentSize = CGSize(width: 1024, height: 720)
        let containerView = NSView(frame: NSRect(origin: .zero, size: contentSize))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        containerView.autoresizingMask = [.width, .height]

        let contentView = ContentView()
            .environmentObject(sharedCalendarViewModel)
            .environmentObject(settingsManager)
        let hostingController = NSHostingController(rootView: AnyView(contentView))
        mainHostingController = hostingController
        hostingController.view.frame = containerView.bounds
        hostingController.view.autoresizingMask = [.width, .height]
        containerView.addSubview(hostingController.view)

        window.contentView = containerView
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        hostingController.view.layoutSubtreeIfNeeded()

        DispatchQueue.main.async { [weak self] in
            self?.applyInitialSettings()
        }
    }
    
    func setupMenuBar() {
        let mainMenu = NSMenu()
        
        // Nower 메뉴 (앱 이름)
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        appMenu.addItem(NSMenuItem(title: "Nower 정보", action: nil, keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "서비스", action: nil, keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Nower 숨기기", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        let hideOthersItem = NSMenuItem(title: "다른 항목 모두 숨기기", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(NSMenuItem(title: "모두 보이기", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "종료 Nower", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // 파일 메뉴
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "파일")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(NSMenuItem(title: "새 일정...", action: nil, keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "닫기", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        
        // 편집 메뉴
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "편집")
        editMenuItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "실행 취소", action: #selector(UndoManager.undo), keyEquivalent: "z"))
        let redoItem = NSMenuItem(title: "다시 실행", action: #selector(UndoManager.redo), keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "잘라내기", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "복사", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "붙여넣기", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "모두 선택", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        
        // 선택영역 메뉴 (View 메뉴)
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "선택영역")
        viewMenuItem.submenu = viewMenu
        viewMenu.addItem(NSMenuItem(title: "이전 달", action: nil, keyEquivalent: ""))
        viewMenu.addItem(NSMenuItem(title: "다음 달", action: nil, keyEquivalent: ""))
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(NSMenuItem(title: "오늘로 이동", action: nil, keyEquivalent: ""))
        
        // 설정 메뉴
        let settingsMenuItem = NSMenuItem()
        mainMenu.addItem(settingsMenuItem)
        let settingsMenu = NSMenu(title: "설정")
        settingsMenuItem.submenu = settingsMenu
        
        // 빠른 설정 서브메뉴
        let quickSettingsItem = NSMenuItem(title: "빠른 설정", action: nil, keyEquivalent: "")
        let quickSettingsMenu = NSMenu()
        
        let pinTopLeftItem = NSMenuItem(title: "좌측 상단 고정", action: #selector(togglePinToTopLeft), keyEquivalent: "")
        pinTopLeftItem.state = settingsManager.isPinToTopLeft ? .on : .off
        
        let alwaysOnTopItem = NSMenuItem(title: "항상 위에 표시", action: #selector(toggleAlwaysOnTop), keyEquivalent: "")
        alwaysOnTopItem.state = settingsManager.isAlwaysOnTop ? .on : .off

        let desktopModeItem = NSMenuItem(title: "배경화면 고정", action: #selector(toggleDesktopMode), keyEquivalent: "")
        desktopModeItem.state = settingsManager.isDesktopMode ? .on : .off

        quickSettingsMenu.addItem(pinTopLeftItem)
        quickSettingsMenu.addItem(alwaysOnTopItem)
        quickSettingsMenu.addItem(NSMenuItem.separator())
        quickSettingsMenu.addItem(desktopModeItem)
        quickSettingsItem.submenu = quickSettingsMenu
        
        settingsMenu.addItem(quickSettingsItem)
        settingsMenu.addItem(NSMenuItem.separator())
        settingsMenu.addItem(NSMenuItem(title: "설정...", action: #selector(openSettings), keyEquivalent: ","))
        settingsMenu.addItem(NSMenuItem.separator())
        settingsMenu.addItem(NSMenuItem(title: "자동 실행 활성화", action: #selector(enableAutoLaunch), keyEquivalent: ""))
        settingsMenu.addItem(NSMenuItem(title: "자동 실행 비활성화", action: #selector(disableAutoLaunch), keyEquivalent: ""))
        
        NSApp.mainMenu = mainMenu
    }


    func applicationWillTerminate(_ notification: Notification) {
        saveWindowPosition()
    }
    
    /// Dock 아이콘 클릭 시 메인 창을 다시 앞으로 가져옴 (창이 안 보일 때 대비)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    private func saveWindowPosition() {
        guard let window = window else { return }
        let position = window.frame.origin
        UserDefaults.standard.set(position.x, forKey: "windowPositionX")
        UserDefaults.standard.set(position.y, forKey: "windowPositionY")
    }

    private func loadWindowPosition() -> NSPoint? {
        let x = UserDefaults.standard.double(forKey: "windowPositionX")
        let y = UserDefaults.standard.double(forKey: "windowPositionY")
        if x == 0 && y == 0 { return nil }
        return NSPoint(x: x, y: y)
    }

    @objc func openSettings() {
        let settingsView = SettingsView().environmentObject(settingsManager)

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        settingsWindow.title = "Nower 설정"
        settingsWindow.center()
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.contentView = SafeHostingView(rootView: settingsView)
        settingsWindow.makeKeyAndOrderFront(nil)
    }

    @objc func enableAutoLaunch() {
        SMLoginItemSetEnabled(appBundleID as CFString, true)
    }

    @objc func disableAutoLaunch() {
        SMLoginItemSetEnabled(appBundleID as CFString, false)
    }
    
    // MARK: - Window Settings Handlers
    
    /// 좌측 상단 고정 기능 변경 처리
    @objc func pinToTopLeftChanged() {
        guard let window = window else { return }
        
        DispatchQueue.main.async {
            let isPinned = self.settingsManager.isPinToTopLeft
            window.setPinToTopLeft(isPinned)
        }
    }
    
    /// 항상 위에 표시 기능 변경 처리
    @objc func alwaysOnTopChanged() {
        guard let window = window else { return }
        
        DispatchQueue.main.async {
            let alwaysOnTop = self.settingsManager.isAlwaysOnTop
            window.setAlwaysOnTop(alwaysOnTop)
        }
    }
    
    /// 배경화면 고정 모드 변경 처리
    @objc func desktopModeChanged() {
        guard let window = window else { return }

        DispatchQueue.main.async {
            let isDesktop = self.settingsManager.isDesktopMode
            window.setDesktopMode(isDesktop)

            // 배경화면 모드와 항상 위에 표시는 상호 배타
            if isDesktop && self.settingsManager.isAlwaysOnTop {
                self.settingsManager.isAlwaysOnTop = false
            }
        }
    }

    /// 배경화면 고정 토글
    @objc func toggleDesktopMode() {
        settingsManager.isDesktopMode.toggle()
        updateMenuBar()
    }

    /// 좌측 상단 고정 토글
    @objc func togglePinToTopLeft() {
        settingsManager.isPinToTopLeft.toggle()
        updateMenuBar()
    }
    
    /// 항상 위에 표시 토글
    @objc func toggleAlwaysOnTop() {
        settingsManager.isAlwaysOnTop.toggle()
        updateMenuBar()
    }
    
    /// 메뉴바 업데이트 (토글 상태 반영)
    private func updateMenuBar() {
        setupMenuBar()
    }
    
    /// 앱 시작 시 저장된 설정들을 적용
    private func applyInitialSettings() {
        guard let window = window else { return }

        // 좌측 상단 고정 적용
        if settingsManager.isPinToTopLeft {
            window.setPinToTopLeft(true)
        }

        // 항상 위에 표시 적용 (배경화면 고정과 상호 배타)
        if settingsManager.isAlwaysOnTop && !settingsManager.isDesktopMode {
            window.setAlwaysOnTop(true)
        }

        // 배경화면 고정 모드 적용
        if settingsManager.isDesktopMode {
            window.setDesktopMode(true)
        }
    }
}
