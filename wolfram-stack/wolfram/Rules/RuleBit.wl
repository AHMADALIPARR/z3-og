(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`RuleBit[rule_Integer,left_Integer,center_Integer,right_Integer] /; 0<=rule<=255&&And@@(MemberQ[{0,1},#]&/@{left,center,right}) := BitAnd[BitShiftRight[rule,4*left+2*center+right],1]
WF`RuleBit[_,_,_,_]:=$Failed
