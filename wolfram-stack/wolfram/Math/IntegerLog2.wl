WF`IntegerLog2[n_Integer] /; n>0 := Module[{k=0,x=n},While[x>=2,x=Quotient[x,2];k++];k]
WF`IntegerLog2[_]:=$Failed
