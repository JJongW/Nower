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
        setupWindow()
        setupStatusBar()
        enableAutoLaunch()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateContentView), name: .init("SettingsChanged"), object: nil)
    }

    func setupWindow() {
        let screenSize = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let savedPosition = loadWindowPosition() ?? NSPoint(x: (screenSize.width - 400) / 2, y: (screenSize.height - 300) / 2)
        let windowFrame = NSRect(origin: savedPosition, size: CGSize(width: 400, height: 300))

        let window = DraggableWindow(
            contentRect: windowFrame,
            styleMask: [.borderless, .titled], // borderless 유지
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .normal
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false // 마우스 이벤트 활성화
        window.makeKeyAndOrderFront(nil)

        window.contentView = NSHostingView(rootView: ContentView().environmentObject(settingsManager))

        self.window = window
        self.window?.makeKeyAndOrderFront(nil)
    }

    @objc func updateContentView() {
        DispatchQueue.main.async { [self] in
            self.window?.contentView = NSHostingView(rootView: ContentView().environmentObject(self.settingsManager))
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        saveWindowPosition()
    }

    // ✅ 마지막 위치 저장
    private func saveWindowPosition() {
        guard let window = window else { return }
        let position = window.frame.origin
        UserDefaults.standard.set(position.x, forKey: "windowPositionX")
        UserDefaults.standard.set(position.y, forKey: "windowPositionY")
    }

    // ✅ 마지막 위치 복원
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
        menu.addItem(NSMenuItem(title: "설정", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "자동 실행 활성화", action: #selector(enableAutoLaunch), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "자동 실행 비활성화", action: #selector(disableAutoLaunch), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func openSettings() {
        let settingsView = SettingsView()
            .environmentObject(SettingsManager())

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        settingsWindow.title = "설정"
        settingsWindow.center()
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
        settingsWindow.makeKeyAndOrderFront(nil)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // Mac 부팅 시 자동 실행 활성화
    @objc func enableAutoLaunch() {
        SMLoginItemSetEnabled(appBundleID as CFString, true)
    }

    // 자동 실행 비활성화
    @objc func disableAutoLaunch() {
        SMLoginItemSetEnabled(appBundleID as CFString, false)
    }
}
