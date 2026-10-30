(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TestProperties[] := Module[{n,rule,bits,packed,next,w,h,i,expected},For[n=1,n<=40,n++,bits=Table[Boole[Mod[7*i*i+3*i+n,11]<5],{i,1,n}];packed=WF`PackBits[bits];If[WF`UnpackBits[packed,n]=!=bits,Return[False]];For[rule=0,rule<=255,rule++,next=WF`ElementaryStep[bits,rule,"Wrap"];If[WF`ElementaryPacked[packed,n,rule,"Wrap"]=!=WF`PackBits[next],Return[False]]]];For[w=1,w<=5,w++,For[h=1,h<=5,h++,bits=Table[Boole[Mod[i*i+2*i,7]<3],{i,1,w*h}];expected=WF`LifeStep[bits,w,h,{3},{2,3},"Wrap"];If[Length[expected]!=w*h||!WF`ValidateBits[expected],Return[False]]]];True]
