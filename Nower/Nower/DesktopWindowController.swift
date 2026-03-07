//
//  DesktopWindowController.swift
//  Nower
//
//  Manages the desktop-level calendar window and opens the Add Schedule window
//  on double-click or when the view requests it via environment.
//

import AppKit
import SwiftUI

/// 데스크톱 위젯 모드에서 "Add Schedule" 창을 열 때 사용하는 콜백.
/// Environment에 주입하여 ContentView의 더블탭/버튼/날짜 클릭이 별도 창으로 열리도록 함.
struct OpenAddScheduleWithDateKey: EnvironmentKey {
    static let defaultValue: ((Date?) -> Void)? = nil
}

extension EnvironmentValues {
    var openAddScheduleWithDate: ((Date?) -> Void)? {
        get { self[OpenAddScheduleWithDateKey.self] }
        set { self[OpenAddScheduleWithDateKey.self] = newValue }
    }
}

final class DesktopWindowController: NSWindowController {

    private let calendarViewModel = CalendarViewModel()
    private let settingsManager = SettingsManager()
    private var hostingController: NSHostingController<AnyView>?
    private weak var addScheduleWindowController: AddScheduleWindowController?

    private let windowSize = CGSize(width: 1024, height: 720)

    init() {
        let window = DesktopCalendarWindow(
            contentRect: NSRect(origin: .zero, size: CGSize(width: 1024, height: 720)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.configureAsDesktopWidget()
        super.init(window: window)
        setupContent()
        positionWindow()
        setupObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        guard let window = window as? DesktopCalendarWindow else { return }

        let openAddSchedule: (Date?) -> Void = { [weak self] date in
            self?.showAddSchedule(initialDate: date)
        }

        let contentView = ContentView()
            .environmentObject(calendarViewModel)
            .environmentObject(settingsManager)
            .environment(\.openAddScheduleWithDate, openAddSchedule)

        let hosting = NSHostingController(rootView: AnyView(contentView))
        hostingController = hosting
        hosting.view.frame = NSRect(origin: .zero, size: windowSize)
        hosting.view.autoresizingMask = [.width, .height]

        let container = NSView(frame: NSRect(origin: .zero, size: windowSize))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        container.autoresizingMask = [.width, .height]
        container.addSubview(hosting.view)

        window.contentView = container
        window.isOpaque = false
        window.backgroundColor = .clear
        container.layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func positionWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let x = visible.minX + 24
        let y = visible.maxY - windowSize.height - 24
        window.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenAddSchedule(_:)),
            name: .desktopCalendarOpenAddSchedule,
            object: nil
        )
    }

    @objc private func handleOpenAddSchedule(_ notification: Notification) {
        let date = notification.userInfo?["initialDate"] as? Date
        showAddSchedule(initialDate: date)
    }

    /// Add Schedule 플로팅 창 표시 (일반 윈도우 레벨, 인터랙티브).
    func showAddSchedule(initialDate: Date?) {
        if let existing = addScheduleWindowController, existing.window?.isVisible == true {
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }
        let addWC = AddScheduleWindowController(
            viewModel: calendarViewModel,
            initialDate: initialDate
        )
        addWC.onWindowClose = { [weak self] in
            guard let self = self else { return }
            if self.addScheduleWindowController === addWC {
                self.addScheduleWindowController = nil
            }
        }
        addScheduleWindowController = addWC
        addWC.showWindow(nil)
        addWC.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
