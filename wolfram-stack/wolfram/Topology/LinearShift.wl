WF`LinearShift[a_List,k_Integer,fill_:0] := Module[{n=Length[a],out,i,j},out=ConstantArray[fill,n];For[i=1,i<=n,i++,j=i-k;If[1<=j<=n,out[[i]]=a[[j]]]];out]
