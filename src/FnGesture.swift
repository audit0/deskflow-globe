import Foundation

// Classifies an isolated Fn tap without retaining key codes or text.
struct FnGesture {
    private var started: TimeInterval?
    private var chord = false

    mutating func reset() { started = nil; chord = false }
    mutating func otherKeyPressed() { if started != nil { chord = true } }
    mutating func modifiersChanged(hasOtherModifiers: Bool) {
        if hasOtherModifiers { chord = true }
    }
    mutating func fnChanged(pressed: Bool, hasOtherModifiers: Bool, time: TimeInterval) -> Bool {
        if pressed {
            if started == nil { started = time; chord = hasOtherModifiers }
            return false
        }
        guard let down = started else { return false }
        started = nil
        return !chord && time >= down && time - down < 0.2
    }
}
