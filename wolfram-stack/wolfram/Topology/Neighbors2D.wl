(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`Neighbors2D[x_Integer,y_Integer,w_Integer,h_Integer,boundary_:"Zero"] := Module[{out={},dx,dy,xx,yy},If[Min[x,y,w,h]<1||x>w||y>h,Return[$Failed]];For[dy=-1,dy<=1,dy++,For[dx=-1,dx<=1,dx++,If[dx==0&&dy==0,Continue[]];xx=x+dx;yy=y+dy;If[boundary==="Wrap",xx=Mod[xx-1,w]+1;yy=Mod[yy-1,h]+1];If[1<=xx<=w&&1<=yy<=h,AppendTo[out,(yy-1)*w+xx]]]];out]
