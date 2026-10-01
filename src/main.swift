import AppKit
import Carbon
import CoreGraphics

// Passive Fn observer. No event injection, keystroke logging, or networking.
final class GlobeDelegate: NSObject, NSApplicationDelegate {
    var tap: CFMachPort?
    var source: CFRunLoopSource?
    var item: NSStatusItem?
    var gesture = FnGesture()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard CGPreflightListenEventAccess() else {
            fail("Allow Deskflow Globe in System Settings → Privacy & Security → Input Monitoring, then launch it again.")
            return
        }
        let mask = (CGEventMask(1) << CGEventType.flagsChanged.rawValue)
                 | (CGEventMask(1) << CGEventType.keyDown.rawValue)
        tap = CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap,
                               options: .listenOnly, eventsOfInterest: mask,
                               callback: globeCallback,
                               userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap = tap else {
            fail("Cannot attach the passive Fn observer. Deskflow settings have not been changed.")
            return
        }
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item?.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Deskflow Globe")
        let menu = NSMenu()
        menu.addItem(withTitle: "Deskflow Globe — tap Fn to switch language", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "Standalone mode: relaunch after the Deskflow server", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        item?.menu = menu
    }

    func receive(_ type: CGEventType, _ event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            gesture.reset()
            if let tap = tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        if type == .keyDown {
            gesture.otherKeyPressed()
            return
        }
        guard type == .flagsChanged else { return }
        let flags = event.flags
        let other: CGEventFlags = [.maskShift, .maskControl, .maskAlternate, .maskCommand]
        let hasOtherModifiers = !flags.intersection(other).isEmpty
        gesture.modifiersChanged(hasOtherModifiers: hasOtherModifiers)
        guard event.getIntegerValueField(.keyboardEventKeycode) == 63 else { return }
        if gesture.fnChanged(pressed: flags.contains(.maskSecondaryFn),
                             hasOtherModifiers: hasOtherModifiers,
                             time: ProcessInfo.processInfo.systemUptime) {
            DispatchQueue.main.async { self.cycleSource() }
        }
    }

    func cycleSource() {
        guard let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let raw = TISCreateInputSourceList(nil, false)?.takeRetainedValue() else { return }
        let sources = (raw as NSArray as! [TISInputSource]).filter {
            text($0, kTISPropertyInputSourceType) == (kTISTypeKeyboardLayout as String)
                && boolean($0, kTISPropertyInputSourceIsEnabled)
                && boolean($0, kTISPropertyInputSourceIsSelectCapable)
        }
        guard sources.count > 1,
              let index = sources.firstIndex(where: { CFEqual($0, current) }) else { return }
        if TISSelectInputSource(sources[(index + 1) % sources.count]) != noErr {
            NSSound.beep()
        }
    }

    func text(_ source: TISInputSource, _ property: CFString) -> String? {
        guard let p = TISGetInputSourceProperty(source, property) else { return nil }
        return Unmanaged<CFString>.fromOpaque(p).takeUnretainedValue() as String
    }
    func boolean(_ source: TISInputSource, _ property: CFString) -> Bool {
        guard let p = TISGetInputSourceProperty(source, property) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(p).takeUnretainedValue())
    }
    func fail(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Deskflow Globe"
        alert.informativeText = message
        alert.runModal()
        NSApp.terminate(nil)
    }
    @objc func quitApp() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) {
        if let tap = tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
    }
}

let globeCallback: CGEventTapCallBack = { _, type, event, info in
    if let info = info {
        Unmanaged<GlobeDelegate>.fromOpaque(info).takeUnretainedValue().receive(type, event)
    }
    return Unmanaged.passUnretained(event)
}
let app = NSApplication.shared
let delegate = GlobeDelegate()
app.delegate = delegate
app.run()
