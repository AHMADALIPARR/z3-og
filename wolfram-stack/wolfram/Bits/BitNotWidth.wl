WF`BitNotWidth[a_Integer,width_Integer] /; width>=0 := BitXor[BitAnd[a,2^width-1],2^width-1]
WF`BitNotWidth[_,_]:=$Failed
