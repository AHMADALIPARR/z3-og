WF`Strides[shape_List] /; WF`ValidateShape[shape] := Module[{n=Length[shape], out, acc=1, i}, out=ConstantArray[1,n]; For[i=n,i>=1,i--,out[[i]]=acc;acc*=shape[[i]]];out]
WF`Strides[_]:=$Failed
