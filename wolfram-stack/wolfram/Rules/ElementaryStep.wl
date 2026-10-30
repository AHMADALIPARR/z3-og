(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`ElementaryStep[bits_List,rule_Integer,boundary_:"Zero"] := Module[{n=Length[bits],out,i,l,c,r},If[!WF`ValidateBits[bits]||n==0||rule<0||rule>255||!MemberQ[{"Zero","Wrap"},boundary],Return[$Failed]];out=ConstantArray[0,n];For[i=1,i<=n,i++,l=If[i>1,bits[[i-1]],If[boundary==="Wrap",bits[[n]],0]];c=bits[[i]];r=If[i<n,bits[[i+1]],If[boundary==="Wrap",bits[[1]],0]];out[[i]]=WF`RuleBit[rule,l,c,r]];out]
