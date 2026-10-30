WF`PackBits[bits_List] /; WF`ValidateBits[bits] := Module[{out=ConstantArray[0,WF`WordsFor[Length[bits]]],i,j},For[i=1,i<=Length[bits],i++,If[bits[[i]]==1,j=Quotient[i-1,64]+1;out[[j]]=BitOr[out[[j]],BitShiftLeft[1,Mod[i-1,64]]]]];out]
WF`PackBits[_]:=$Failed
