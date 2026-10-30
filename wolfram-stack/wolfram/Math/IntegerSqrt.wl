WF`IntegerSqrt[n_Integer] /; n>=0 := Module[{lo=0,hi=n+1,mid},While[hi-lo>1,mid=Quotient[lo+hi,2];If[mid*mid<=n,lo=mid,hi=mid]];lo]
WF`IntegerSqrt[_]:=$Failed
