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
        window.contentView = NSHostingView(rootView: contentView)

        // ✅ 창 띄우기
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    @objc func updateContentView() {
        guard let window = window else { return }
        DispatchQueue.main.async {
            window.contentView = NSHostingView(
                rootView: ContentView()
                    .environmentObject(self.settingsManager)
            )
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
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
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
}
