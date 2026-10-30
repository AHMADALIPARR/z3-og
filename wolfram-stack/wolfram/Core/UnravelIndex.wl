(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`UnravelIndex[index_Integer,shape_List] := Module[{s=WF`Strides[shape],r=index-1,n,i,out},If[s===$Failed||index<1||index>WF`ShapeSize[shape],Return[$Failed]];n=Length[shape];out=ConstantArray[1,n];For[i=1,i<=n,i++,out[[i]]=Quotient[r,s[[i]]]+1;r=Mod[r,s[[i]]]];out]
WF`UnravelIndex[_,_]:=$Failed
