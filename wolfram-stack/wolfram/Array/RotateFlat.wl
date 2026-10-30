WF`RotateFlat[a_List,k_Integer] := Module[{n=Length[a],out,i,j},If[n==0,Return[{}]];out=Table[Null,{n}];For[i=1,i<=n,i++,j=Mod[i-1-k,n]+1;out[[i]]=a[[j]]];out]
