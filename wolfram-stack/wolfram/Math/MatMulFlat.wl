(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`MatMulFlat[a_List,b_List,m_Integer,k_Integer,n_Integer] := Module[{out,i,j,t,s},If[Min[m,k,n]<0||Length[a]!=m*k||Length[b]!=k*n,Return[$Failed]];out=ConstantArray[0,m*n];For[i=1,i<=m,i++,For[j=1,j<=n,j++,s=0;For[t=1,t<=k,t++,s+=a[[(i-1)*k+t]]*b[[(t-1)*n+j]]];out[[(i-1)*n+j]]=s]];out]
