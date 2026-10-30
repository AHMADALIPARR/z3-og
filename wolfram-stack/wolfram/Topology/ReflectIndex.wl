WF`ReflectIndex[i_Integer,n_Integer] /; n>0 := Module[{p,j},If[n==1,Return[1]];p=2*n-2;j=Mod[i-1,p];If[j<n,j+1,p-j+1]]
WF`ReflectIndex[_,_]:=$Failed
