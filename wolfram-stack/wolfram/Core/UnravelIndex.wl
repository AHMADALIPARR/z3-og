WF`UnravelIndex[index_Integer,shape_List] := Module[{s=WF`Strides[shape],r=index-1,n,i,out},If[s===$Failed||index<1||index>WF`ShapeSize[shape],Return[$Failed]];n=Length[shape];out=ConstantArray[1,n];For[i=1,i<=n,i++,out[[i]]=Quotient[r,s[[i]]]+1;r=Mod[r,s[[i]]]];out]
WF`UnravelIndex[_,_]:=$Failed
