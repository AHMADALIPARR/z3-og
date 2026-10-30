WF`PeriodicIndex[i_Integer,n_Integer] /; n>0 := Mod[i-1,n]+1
WF`PeriodicIndex[_,_]:=$Failed
