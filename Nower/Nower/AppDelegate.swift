//
//  AppDelegate.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//
import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: DraggableWindow?
    var settingsManager = SettingsManager()
    var statusItem: NSStatusItem?
    let appBundleID = "pr.jongwon.Nower"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainWindow()
        setupStatusBar()
        enableAutoLaunch()

        NotificationCenter.default.addObserver(self, selector: #selector(updateContentView), name: .init("SettingsChanged"), object: nil)
        
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

    @objc func updateContentView() {
        guard let window = window else { return }
        DispatchQueue.main.async {
            let contentView = ContentView().environmentObject(self.settingsManager)
            let hostingView = SafeHostingView(rootView: contentView)
            window.contentView = hostingView
        }
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

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar App")
        }

        let menu = NSMenu()
        
        // 빠른 설정 메뉴
        let quickSettingsItem = NSMenuItem(title: "빠른 설정", action: nil, keyEquivalent: "")
        let quickSettingsMenu = NSMenu()
        
        let pinTopLeftItem = NSMenuItem(title: "좌측 상단 고정", action: #selector(togglePinToTopLeft), keyEquivalent: "")
        pinTopLeftItem.state = settingsManager.isPinToTopLeft ? .on : .off
        
        let alwaysOnTopItem = NSMenuItem(title: "항상 위에 표시", action: #selector(toggleAlwaysOnTop), keyEquivalent: "")
        alwaysOnTopItem.state = settingsManager.isAlwaysOnTop ? .on : .off
        
        quickSettingsMenu.addItem(pinTopLeftItem)
        quickSettingsMenu.addItem(alwaysOnTopItem)
        quickSettingsItem.submenu = quickSettingsMenu
        
        menu.addItem(quickSettingsItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "설정", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "자동 실행 활성화", action: #selector(enableAutoLaunch), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "자동 실행 비활성화", action: #selector(disableAutoLaunch), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func openSettings() {
        let settingsView = SettingsView().environmentObject(settingsManager)

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        settingsWindow.title = "설정"
        settingsWindow.center()
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.contentView = SafeHostingView(rootView: settingsView)
        settingsWindow.makeKeyAndOrderFront(nil)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
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
    
    // MARK: - Quick Settings Toggle Methods
    
    /// 좌측 상단 고정 토글
    @objc func togglePinToTopLeft() {
        settingsManager.isPinToTopLeft.toggle()
        updateStatusBarMenu()
    }
    
    /// 항상 위에 표시 토글
    @objc func toggleAlwaysOnTop() {
        settingsManager.isAlwaysOnTop.toggle()
        updateStatusBarMenu()
    }
    
    /// 상태바 메뉴 업데이트 (토글 상태 반영)
    private func updateStatusBarMenu() {
        setupStatusBar() // 간단하게 메뉴를 다시 생성
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
        
        // 투명도 적용
        window.setWindowOpacity(settingsManager.opacity)
        
        print("🚀 [AppDelegate] 초기 설정 적용 완료")
        print("   - 좌측 상단 고정: \(settingsManager.isPinToTopLeft)")
        print("   - 항상 위에 표시: \(settingsManager.isAlwaysOnTop)")
        print("   - 투명도: \(Int(settingsManager.opacity * 100))%")
    }
}
