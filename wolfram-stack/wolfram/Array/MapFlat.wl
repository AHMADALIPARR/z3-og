WF`MapFlat[f_,a_List] := Module[{n=Length[a],out,i},out=Table[Null,{n}];For[i=1,i<=n,i++,out[[i]]=f[a[[i]]]];out]
