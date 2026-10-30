(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`FlatTranspose2D[a_Association] := Module[{h,w,out,x,y},If[!WF`FlatValid[a]||Length[a["Shape"]]!=2,Return[$Failed]];{h,w}=a["Shape"];out=ConstantArray[0,h*w];For[y=1,y<=h,y++,For[x=1,x<=w,x++,out[[(x-1)*h+y]]=a["Data"][[ (y-1)*w+x ]]]];<|"Shape"->{w,h},"Data"->out|>]
