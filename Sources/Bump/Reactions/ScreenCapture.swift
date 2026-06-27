import ScreenCaptureKit
import CoreGraphics
import AppKit

/// One-shot screen grab used by the glitch reaction to distort the *actual*
/// screen contents. Uses ScreenCaptureKit; requires Screen Recording permission
/// (the first capture triggers the system prompt). Returns nil if unavailable,
/// in which case the glitch falls back to a synthetic version.
enum ScreenCapture {
    static func grab() async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = displayUnderMouse(content.displays) ?? content.displays.first else { return nil }
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = display.width
            config.height = display.height
            config.showsCursor = false
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } catch {
            return nil
        }
    }

    private static func displayUnderMouse(_ displays: [SCDisplay]) -> SCDisplay? {
        let mouse = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            guard NSMouseInRect(mouse, screen.frame, false),
                  let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            else { continue }
            return displays.first { $0.displayID == num }
        }
        return nil
    }
}
