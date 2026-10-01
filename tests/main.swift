import Foundation

func check(_ condition: Bool, _ message: String) {
    if !condition { fatalError(message) }
}
var g = FnGesture()
check(!g.fnChanged(pressed: false, hasOtherModifiers: false, time: 0), "Unmatched release must be ignored")
check(!g.fnChanged(pressed: true, hasOtherModifiers: false, time: 1), "Press must not switch")
check(g.fnChanged(pressed: false, hasOtherModifiers: false, time: 1.1), "Short isolated Fn must switch")
_ = g.fnChanged(pressed: true, hasOtherModifiers: false, time: 2)
check(!g.fnChanged(pressed: false, hasOtherModifiers: false, time: 2.5), "Held Fn must not switch")
_ = g.fnChanged(pressed: true, hasOtherModifiers: false, time: 3)
g.otherKeyPressed()
check(!g.fnChanged(pressed: false, hasOtherModifiers: false, time: 3.1), "Fn chord must not switch")
_ = g.fnChanged(pressed: true, hasOtherModifiers: false, time: 4)
g.modifiersChanged(hasOtherModifiers: true)
g.modifiersChanged(hasOtherModifiers: false)
check(!g.fnChanged(pressed: false, hasOtherModifiers: false, time: 4.1), "Released modifier must still cancel tap")
_ = g.fnChanged(pressed: true, hasOtherModifiers: true, time: 5)
check(!g.fnChanged(pressed: false, hasOtherModifiers: false, time: 5.1), "Existing modifier must cancel tap")
_ = g.fnChanged(pressed: true, hasOtherModifiers: false, time: 6)
g.reset()
check(!g.fnChanged(pressed: false, hasOtherModifiers: false, time: 6.1), "Reset after tap interruption must cancel release")
_ = g.fnChanged(pressed: true, hasOtherModifiers: false, time: 7)
check(g.fnChanged(pressed: false, hasOtherModifiers: false, time: 7.1), "Next isolated tap must recover")
print("Fn gesture regression checks passed")
