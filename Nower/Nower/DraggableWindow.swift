//
//  DraggableWindow.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import Foundation
import Cocoa

class DraggableWindow: NSWindow {
    private var initialClickLocation: NSPoint?

    override func mouseDown(with event: NSEvent) {
        self.initialClickLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let initialClickLocation = initialClickLocation else { return }

        let screenLocation = NSEvent.mouseLocation // 전체 화면 좌표
        let newOrigin = NSPoint(
            x: screenLocation.x - initialClickLocation.x,
            y: screenLocation.y - initialClickLocation.y
        )

        DispatchQueue.main.async {
            self.setFrameOrigin(newOrigin)
        }
    }
}


