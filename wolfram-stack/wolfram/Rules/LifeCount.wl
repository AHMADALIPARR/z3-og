(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`LifeCount[bits_List,w_Integer,h_Integer,x_Integer,y_Integer,boundary_:"Zero"] := Module[{dx,dy,xx,yy,s=0},If[w<=0||h<=0||Length[bits]!=w*h||!WF`ValidateBits[bits]||x<1||x>w||y<1||y>h||!MemberQ[{"Zero","Wrap"},boundary],Return[$Failed]];For[dy=-1,dy<=1,dy++,For[dx=-1,dx<=1,dx++,If[dx==0&&dy==0,Continue[]];xx=x+dx;yy=y+dy;If[boundary==="Wrap",xx=Mod[xx-1,w]+1;yy=Mod[yy-1,h]+1];If[1<=xx<=w&&1<=yy<=h,s+=bits[[(yy-1)*w+xx]]]]];s]
