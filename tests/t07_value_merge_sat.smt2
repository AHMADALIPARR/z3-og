; z3-og self-test. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty. Licensed under
; the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 --
; see LICENSE at the repository root.
(declare-const x Int)
(declare-const y Int)
(declare-fun f (Int) Int)
(assert (>= x 0))
(assert (<= x 10))
(assert (>= y 0))
(assert (<= y 10))
(assert (not (= (f x) (f y))))
(check-sat)
