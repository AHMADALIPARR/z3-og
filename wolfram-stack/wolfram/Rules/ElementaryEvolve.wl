(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`ElementaryEvolve[bits_List,rule_Integer,steps_Integer,boundary_:"Zero"] := Module[{state=bits,out,i},If[steps<0||!WF`ValidateBits[bits]||Length[bits]==0,Return[$Failed]];out={state};For[i=1,i<=steps,i++,state=WF`ElementaryStep[state,rule,boundary];If[state===$Failed,Return[$Failed]];AppendTo[out,state]];out]
