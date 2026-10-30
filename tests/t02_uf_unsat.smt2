; z3-og self-test. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty. Licensed under
; the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 --
; see LICENSE at the repository root.
(declare-sort U 0)
(declare-const a U)
(declare-const b U)
(declare-fun f (U) U)
(assert (= a b))
(assert (not (= (f a) (f b))))
(check-sat)
