WF`BitRangeExtract[words_List,start_Integer,count_Integer] := Module[{out=ConstantArray[0,Max[0,count]],i,v},If[start<0||count<0||start+count>64*Length[words],Return[$Failed]];For[i=0,i<count,i++,v=WF`BitGet[words,start+i];If[v===$Failed,Return[$Failed]];out[[i+1]]=v];out]
WF`BitRangeExtract[_,_,_]:=$Failed
