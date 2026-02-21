import AppKit

enum WindowManager {
    static func snapFocusedWindow(to region: SnapRegion) {
        guard AccessibilityHelper.isGranted() else {
            NSLog("[WindowManager] Accessibility not granted")
            return
        }

        // Get the frontmost app — since we're an LSUIElement (agent) app,
        // NSWorkspace.shared.frontmostApplication returns the user's active app, not us
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            NSLog("[WindowManager] No frontmost application")
            return
        }

        let pid = frontApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var focusedWindowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowRef)
        guard result == .success, let windowRef = focusedWindowRef else {
            NSLog(
                "[WindowManager] Could not get focused window from \(frontApp.localizedName ?? "unknown") (pid: \(pid)), error: \(result.rawValue)"
            )
            return
        }
        let window = windowRef as! AXUIElement

        let screen = screenForWindow(window) ?? NSScreen.main ?? NSScreen.screens.first!
        let settings = AppSettings.shared
        let targetFrame = region.frame(on: screen, settings: settings)

        NSLog(
            "[WindowManager] Snapping \(frontApp.localizedName ?? "?") to \(region) -> \(targetFrame)"
        )

        setWindowPosition(window, point: targetFrame.origin)
        setWindowSize(window, size: targetFrame.size)
    }

    // MARK: - Private

    private static func screenForWindow(_ window: AXUIElement) -> NSScreen? {
        guard let pos = getWindowPosition(window) else { return nil }

        let primaryHeight = NSScreen.screens.first!.frame.height

        // Convert AX point (top-left origin) to NSScreen coordinates (bottom-left origin)
        let nsY = primaryHeight - pos.y

        for screen in NSScreen.screens {
            if pos.x >= screen.frame.minX && pos.x < screen.frame.maxX
                && nsY >= screen.frame.minY && nsY < screen.frame.maxY
            {
                return screen
            }
        }
        return nil
    }

    private static func getWindowPosition(_ window: AXUIElement) -> CGPoint? {
        var posRef: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
                == .success
        else {
            return nil
        }
        var point = CGPoint.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &point)
        return point
    }

    private static func setWindowPosition(_ window: AXUIElement, point: CGPoint) {
        var p = point
        if let value = AXValueCreate(.cgPoint, &p) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
        }
    }

    private static func setWindowSize(_ window: AXUIElement, size: CGSize) {
        var s = size
        if let value = AXValueCreate(.cgSize, &s) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
        }
    }
}
