(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`IntegerSqrt[n_Integer] /; n>=0 := Module[{lo=0,hi=n+1,mid},While[hi-lo>1,mid=Quotient[lo+hi,2];If[mid*mid<=n,lo=mid,hi=mid]];lo]
WF`IntegerSqrt[_]:=$Failed
