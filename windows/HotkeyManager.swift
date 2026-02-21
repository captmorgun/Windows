import AppKit
import CoreGraphics

final class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var heldArrows: Set<Int64> = []
    private var shiftHeld: Bool = false
    private var retryTimer: Timer?

    // Arrow keycodes: Left=123, Right=124, Down=125, Up=126
    private static let arrowKeyCodes: Set<Int64> = [123, 124, 125, 126]
    // C keycode: 8
    private static let centerKeyCode: Int64 = 8

    func start() {
        guard eventTap == nil else { return }

        // On macOS 10.15+, CGEventTap requires Input Monitoring permission
        let hasListenAccess = CGPreflightListenEventAccess()
        let hasTrusted = AXIsProcessTrusted()
        NSLog(
            "[HotkeyManager] AXIsProcessTrusted: \(hasTrusted), CGPreflightListenEventAccess: \(hasListenAccess)"
        )

        if !hasListenAccess {
            NSLog("[HotkeyManager] Requesting Input Monitoring access...")
            CGRequestListenEventAccess()
        }

        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: hotkeyCallback,
                userInfo: selfPtr
            )
        else {
            NSLog("[HotkeyManager] Failed to create event tap. Will retry every 3 seconds...")
            NSLog("[HotkeyManager] Please enable this app in:")
            NSLog("[HotkeyManager]   System Settings > Privacy & Security > Input Monitoring")
            NSLog("[HotkeyManager]   System Settings > Privacy & Security > Accessibility")
            startRetryTimer()
            return
        }

        retryTimer?.invalidate()
        retryTimer = nil

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        NSLog("[HotkeyManager] Event tap started successfully!")
    }

    func stop() {
        retryTimer?.invalidate()
        retryTimer = nil
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
        heldArrows.removeAll()
    }

    private func startRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            NSLog("[HotkeyManager] Retrying event tap creation...")
            self?.start()
        }
    }

    fileprivate func handleEvent(_ proxy: CGEventTapProxy, type: CGEventType, event: CGEvent)
        -> Unmanaged<CGEvent>?
    {
        // Re-enable tap if it was disabled by the system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // For flagsChanged, track modifier and shift state
        if type == .flagsChanged {
            let requiredFlag = AppSettings.shared.modifierKey.cgEventFlag
            if !event.flags.contains(requiredFlag) {
                heldArrows.removeAll()
            }
            shiftHeld = event.flags.contains(.maskShift)
            return Unmanaged.passUnretained(event)
        }

        // Only process keyDown / keyUp from here
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        let requiredFlag2 = AppSettings.shared.modifierKey.cgEventFlag
        guard event.flags.contains(requiredFlag2) else {
            return Unmanaged.passUnretained(event)
        }

        // Modifier + C = center window
        if keyCode == Self.centerKeyCode && type == .keyDown {
            WindowManager.snapFocusedWindow(to: .center)
            return nil
        }

        // Only care about arrow keys
        guard Self.arrowKeyCodes.contains(keyCode) else {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown {
            heldArrows.insert(keyCode)

            if let region = SnapRegion.from(arrows: heldArrows, shiftHeld: shiftHeld) {
                WindowManager.snapFocusedWindow(to: region)
            }

            // Consume the event
            return nil

        } else if type == .keyUp {
            heldArrows.remove(keyCode)
            return nil
        }

        return Unmanaged.passUnretained(event)
    }
}

private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
    return manager.handleEvent(proxy, type: type, event: event)
}
