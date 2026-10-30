; z3-og self-test. Copyright (c) 2026 Ahmad Ali Parr. Licensed under
; the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 --
; see LICENSE at the repository root.
; 2x + 3y = 12 with x < y and x > 0 has the rational solution x=3/2, y=3
; but NO integer solution. A solver that relaxes to the rationals gets this
; wrong; z3 (system oracle) answers unsat, and so must we.
(declare-const x Int)
(declare-const y Int)
(assert (= (+ (* 2 x) (* 3 y)) 12))
(assert (< x y))
(assert (> x 0))
(check-sat)
