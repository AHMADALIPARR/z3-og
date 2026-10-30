WF`PowerInteger[x_,n_Integer] /; n>=0 := Module[{a=x,k=n,y=1},While[k>0,If[OddQ[k],y*=a];a*=a;k=Quotient[k,2]];y]
WF`PowerInteger[_,_]:=$Failed
