; z3-og self-test. Copyright (c) 2026 Ahmad Ali Parr. Licensed under
; the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 --
; see LICENSE at the repository root.
(declare-const x Int)
(declare-const y Int)
(declare-fun f (Int) Int)
(assert (= y 3))
(assert (= (f x) (f y)))
(assert (= x y))
(check-sat)
