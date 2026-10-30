WF`ReflectShift[a_List,k_Integer] := Module[{n=Length[a],out,i},If[n==0,Return[{}]];out=Table[Null,{n}];For[i=1,i<=n,i++,out[[i]]=a[[WF`ReflectIndex[i-k,n]]]];out]
