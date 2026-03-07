//
//  AddScheduleWindowController.swift
//  Nower
//
//  Normal titled floating window for "Add Schedule". Shown at normal window level,
//  interactive. Closes when user saves or cancels (AddEventView dismisses).
//

import AppKit
import SwiftUI

/// Add Schedule 플로팅 창. 일반 타이틀/닫기, 일반 윈도우 레벨.
final class AddScheduleWindowController: NSWindowController {

    private let viewModel: CalendarViewModel
    private var initialDate: Date?
    var onWindowClose: (() -> Void)?

    init(viewModel: CalendarViewModel, initialDate: Date?) {
        self.viewModel = viewModel
        self.initialDate = initialDate
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("새 일정", comment: "Add Schedule window title")
        window.level = .normal
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
        setupContent()
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        guard let window = window else { return }
        let root = AddScheduleWindowContent(
            viewModel: viewModel,
            initialDate: initialDate,
            onDismiss: { [weak self] in
                self?.closeWindow()
            }
        )
        let hosting = NSHostingController(rootView: root)
        hosting.view.frame = window.contentView?.bounds ?? .zero
        hosting.view.autoresizingMask = [.width, .height]
        window.contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView?.addSubview(hosting.view)
    }

    func setInitialDate(_ date: Date?) {
        initialDate = date
        // AddEventView is created with initial date; reopening would need view refresh. No-op for existing window.
    }

    private func closeWindow() {
        window?.close()
        onWindowClose?()
    }
}

extension AddScheduleWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        onWindowClose?()
    }
}

// MARK: - SwiftUI wrapper that bridges AddEventView dismiss to window close

private struct AddScheduleWindowContent: View {
    @ObservedObject var viewModel: CalendarViewModel
    let initialDate: Date?
    var onDismiss: () -> Void

    @State private var isPresented = true
    @State private var selectedColor = ""

    var body: some View {
        AddEventView(
            initialDate: initialDate,
            selectedColor: $selectedColor,
            isPopupVisible: $isPresented
        )
        .environmentObject(viewModel)
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                onDismiss()
            }
        }
    }
}
