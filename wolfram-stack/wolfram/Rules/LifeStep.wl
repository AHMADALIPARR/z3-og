(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`LifeStep[bits_List,w_Integer,h_Integer,birth_List:{3},survive_List:{2,3},boundary_:"Zero"] := Module[{out,x,y,k,alive},If[w<=0||h<=0||Length[bits]!=w*h||!WF`ValidateBits[bits]||!SubsetQ[Range[0,8],birth]||!SubsetQ[Range[0,8],survive],Return[$Failed]];out=ConstantArray[0,w*h];For[y=1,y<=h,y++,For[x=1,x<=w,x++,k=WF`LifeCount[bits,w,h,x,y,boundary];If[k===$Failed,Return[$Failed]];alive=bits[[(y-1)*w+x]];out[[(y-1)*w+x]]=Boole[If[alive==1,MemberQ[survive,k],MemberQ[birth,k]]]]];out]
