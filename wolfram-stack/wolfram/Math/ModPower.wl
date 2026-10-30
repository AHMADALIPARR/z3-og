(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`ModPower[b_Integer,e_Integer,m_Integer] /; e>=0&&m>0 := Module[{a=Mod[b,m],k=e,result=Mod[1,m]},While[k>0,If[OddQ[k],result=Mod[result*a,m]];a=Mod[a*a,m];k=Quotient[k,2]];result]
WF`ModPower[_,_,_]:=$Failed
