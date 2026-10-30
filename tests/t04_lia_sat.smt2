; z3-og self-test. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty. Licensed under
; the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 --
; see LICENSE at the repository root.
(declare-const x Int)
(declare-const y Int)
(assert (= (+ (* 2 x) (* 3 y)) 13))
(assert (< x y))
(assert (> x 0))
(check-sat)
