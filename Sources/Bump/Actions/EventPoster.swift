import Foundation
import AppKit
import CoreGraphics

/// Low-level synthetic event helpers. Posting keyboard events to the system
/// requires Accessibility permission (see `Permissions`).
enum EventPoster {

    // MARK: Keyboard chords

    /// Common virtual key codes (ANSI).
    enum Key: CGKeyCode {
        case c = 8, v = 9, q = 12
        case three = 20, four = 21
        case left = 123, right = 124, up = 126
    }

    static func postKey(_ key: Key, flags: CGEventFlags = []) {
        let src = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: key.rawValue, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: src, virtualKey: key.rawValue, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }

    // MARK: System-defined (media) keys

    /// NX_KEYTYPE_* codes from IOKit's ev_keymap.h.
    enum MediaKey: Int32 {
        case soundUp = 0, soundDown = 1, mute = 7
        case play = 16, next = 17, previous = 18
    }

    static func postMediaKey(_ key: MediaKey) {
        func emit(down: Bool) {
            let flags: NSEvent.ModifierFlags = down ? NSEvent.ModifierFlags(rawValue: 0xA00)
                                                    : NSEvent.ModifierFlags(rawValue: 0xB00)
            let data1 = Int((key.rawValue << 16) | ((down ? 0xA : 0xB) << 8))
            guard let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            ) else { return }
            event.cgEvent?.post(tap: .cghidEventTap)
        }
        emit(down: true)
        emit(down: false)
    }
}
