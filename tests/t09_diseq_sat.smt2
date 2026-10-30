; z3-og self-test. Copyright (c) 2026 Ahmad Ali Parr. Licensed under
; the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 --
; see LICENSE at the repository root.
(declare-const x Int)
(assert (>= x 4))
(assert (<= x 6))
(assert (not (= x 5)))
(assert (not (= x 4)))
(check-sat)
