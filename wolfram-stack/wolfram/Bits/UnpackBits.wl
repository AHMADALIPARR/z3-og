WF`UnpackBits[words_List,n_Integer] /; n>=0&&Length[words]>=WF`WordsFor[n] := Module[{out=ConstantArray[0,n],i},For[i=0,i<n,i++,out[[i+1]]=WF`BitGet[words,i]];out]
WF`UnpackBits[_,_]:=$Failed
