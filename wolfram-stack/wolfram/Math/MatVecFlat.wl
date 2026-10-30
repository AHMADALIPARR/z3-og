(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`MatVecFlat[mat_List,vec_List,rows_Integer,cols_Integer] := Module[{out,i,j,s},If[rows<0||cols<0||Length[mat]!=rows*cols||Length[vec]!=cols,Return[$Failed]];out=ConstantArray[0,rows];For[i=1,i<=rows,i++,s=0;For[j=1,j<=cols,j++,s+=mat[[(i-1)*cols+j]]*vec[[j]]];out[[i]]=s];out]
