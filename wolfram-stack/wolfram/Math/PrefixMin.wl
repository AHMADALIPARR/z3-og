WF`PrefixMin[a_List] := Module[{out=a,m,i},If[Length[a]==0,Return[{}]];m=a[[1]];For[i=2,i<=Length[a],i++,If[a[[i]]<m,m=a[[i]]];out[[i]]=m];out]
