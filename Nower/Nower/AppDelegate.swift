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
    var settingsManager = SettingsManager()
    let appBundleID = "pr.jongwon.Nower"

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
    }

    func setupMainWindow() {
        let screenSize = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let savedPosition = loadWindowPosition() ?? NSPoint(x: (screenSize.width - 1024) / 2,
                                                            y: (screenSize.height - 720) / 2)
        let windowFrame = NSRect(origin: savedPosition, size: CGSize(width: 1024, height: 720))

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
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        
        // 배경 드래그로 창 이동 비활성화 (타이틀바에서만 이동 가능)
        window.isMovableByWindowBackground = false

        let contentView = ContentView().environmentObject(settingsManager)
        let hostingView = SafeHostingView(rootView: contentView)
        window.contentView = hostingView

        // ✅ 창 띄우기
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
        
        // 저장된 설정 적용
        DispatchQueue.main.async {
            self.applyInitialSettings()
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
        
        quickSettingsMenu.addItem(pinTopLeftItem)
        quickSettingsMenu.addItem(alwaysOnTopItem)
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
            
            print("📍 [AppDelegate] 좌측 상단 고정: \(isPinned ? "활성화" : "비활성화")")
        }
    }
    
    /// 항상 위에 표시 기능 변경 처리
    @objc func alwaysOnTopChanged() {
        guard let window = window else { return }
        
        DispatchQueue.main.async {
            let alwaysOnTop = self.settingsManager.isAlwaysOnTop
            window.setAlwaysOnTop(alwaysOnTop)
            
            print("⬆️ [AppDelegate] 항상 위에 표시: \(alwaysOnTop ? "활성화" : "비활성화")")
        }
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
        
        // 항상 위에 표시 적용
        if settingsManager.isAlwaysOnTop {
            window.setAlwaysOnTop(true)
        }
        
        #if DEBUG
        print("🚀 [AppDelegate] 초기 설정 적용 완료")
        print("   - 좌측 상단 고정: \(settingsManager.isPinToTopLeft)")
        print("   - 항상 위에 표시: \(settingsManager.isAlwaysOnTop)")
        #endif
    }
}
