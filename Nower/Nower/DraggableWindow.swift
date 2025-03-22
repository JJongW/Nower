//
//  DraggableWindow.swift
//  Nower
//
//  Created by 신종원 on 3/3/25.
//

import Cocoa

class DraggableWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
