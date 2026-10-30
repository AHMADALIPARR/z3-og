(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`PowerInteger[x_,n_Integer] /; n>=0 := Module[{a=x,k=n,y=1},While[k>0,If[OddQ[k],y*=a];a*=a;k=Quotient[k,2]];y]
WF`PowerInteger[_,_]:=$Failed
