(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`Strides[shape_List] /; WF`ValidateShape[shape] := Module[{n=Length[shape], out, acc=1, i}, out=ConstantArray[1,n]; For[i=n,i>=1,i--,out[[i]]=acc;acc*=shape[[i]]];out]
WF`Strides[_]:=$Failed
