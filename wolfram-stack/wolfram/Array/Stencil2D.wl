(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`Stencil2D[data_List,w_Integer,h_Integer,kernel_List,boundary_:"Zero"] := Module[{kh=Length[kernel],kw,cy,cx,out,x,y,dx,dy,xx,yy,s,k},If[w<=0||h<=0||w*h!=Length[data]||kh==0||!MatrixQ[kernel]||!MemberQ[{"Zero","Wrap"},boundary],Return[$Failed]];kw=Length[kernel[[1]]];If[EvenQ[kh]||EvenQ[kw]||!And@@(Length[#]==kw&/@kernel),Return[$Failed]];cy=Quotient[kh,2];cx=Quotient[kw,2];out=ConstantArray[0,w*h];For[y=1,y<=h,y++,For[x=1,x<=w,x++,s=0;For[dy=-cy,dy<=cy,dy++,For[dx=-cx,dx<=cx,dx++,xx=x+dx;yy=y+dy;If[boundary==="Wrap",xx=Mod[xx-1,w]+1;yy=Mod[yy-1,h]+1];If[1<=xx<=w&&1<=yy<=h,s+=kernel[[dy+cy+1,dx+cx+1]]*data[[(yy-1)*w+xx]]]]];out[[(y-1)*w+x]]=s]];out]
