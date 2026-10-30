-- z3-og -- hand-rolled SMT stack (clean-room remake in the original
-- Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
-- Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
-- LICENSE v1.0 -- see LICENSE at the repository root. Commercial
-- exploitation requires separate written authorisation; publication,
-- access, download, visibility, or possession is not authorisation.
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant
import Mathlib.LinearAlgebra.Matrix.Invertible

open Matrix

namespace GoldilocksLoom

/-- The Goldilocks Prime p = 2^64 - 2^32 + 1 -/
def p : ℕ := 18446744069414584321

/-- The Goldilocks Field F_p -/
abbrev GoldilocksField := ZMod p

/-- The 4x4 MixColumns Matrix over Goldilocks Field -/
def mixColumnsMatrix : Matrix (Fin 4) (Fin 4) GoldilocksField :=
  !![ 2, 3, 1, 1 ;
      1, 2, 3, 1 ;
      1, 1, 2, 3 ;
      3, 1, 1, 2 ]

/-- Computes the determinant of the 4x4 MixColumns matrix in Lean 4 -/
theorem mixColumns_det : det mixColumnsMatrix = (20 : GoldilocksField) := by
  -- Expand the 4x4 determinant via finite index evaluation
  decide

/-- Proof that 20 is not congruent to 0 modulo Goldilocks Prime p -/
theorem det_ne_zero : (20 : GoldilocksField) ≠ 0 := by
  intro h
  -- Unfold ZMod equality to raw integer congruence check
  have h_mod : 20 % p = 0 := by exact (ZMod.val_eq_zero_iff 20).mp h
  contradiction

/-- Main Theorem: The Goldilocks MixColumns matrix is invertible over F_p -/
theorem mixColumns_is_invertible : IsUnit (mixColumnsMatrix.det) := by
  rw [mixColumns_det]
  exact IsUnit.mk0 (20 : GoldilocksField) det_ne_zero

/-- Construct explicit Invertible instance for Matrix Operations -/
noncomputable instance mixColumnsInvertible : Invertible mixColumnsMatrix :=
  invertibleOfIsUnitDet mixColumnsMatrix mixColumns_is_invertible

end GoldilocksLoom
