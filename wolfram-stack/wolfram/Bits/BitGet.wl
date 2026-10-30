WF`BitGet[words_List,i_Integer] /; i>=0&&Quotient[i,64]<Length[words] := BitAnd[BitShiftRight[words[[Quotient[i,64]+1]],Mod[i,64]],1]
WF`BitGet[_,_]:=$Failed
