; z3-og self-test. Copyright (c) 2026 Ahmad Ali Parr. Licensed under
; the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE LICENSE v1.0 --
; see LICENSE at the repository root.
(declare-const p Bool)
(declare-const q Bool)
(assert (=> p q))
(assert p)
(assert (not q))
(check-sat)
