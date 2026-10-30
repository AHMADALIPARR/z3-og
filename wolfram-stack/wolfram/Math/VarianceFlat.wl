WF`VarianceFlat[a_List] := Module[{m,s=0,i,n=Length[a]},If[n==0,Return[$Failed]];m=WF`MeanFlat[a];For[i=1,i<=n,i++,s+=(a[[i]]-m)^2];s/n]
