(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`PackBits[bits_List] /; WF`ValidateBits[bits] := Module[{out=ConstantArray[0,WF`WordsFor[Length[bits]]],i,j},For[i=1,i<=Length[bits],i++,If[bits[[i]]==1,j=Quotient[i-1,64]+1;out[[j]]=BitOr[out[[j]],BitShiftLeft[1,Mod[i-1,64]]]]];out]
WF`PackBits[_]:=$Failed
