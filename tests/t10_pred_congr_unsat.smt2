; z3-og self-test. Copyright (c) 2026 Ahmad Ali Parr. Licensed under
; the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 --
; see LICENSE at the repository root.
(declare-sort U 0)
(declare-const a U)
(declare-const b U)
(declare-fun p (U) Bool)
(assert (= a b))
(assert (p a))
(assert (not (p b)))
(check-sat)
