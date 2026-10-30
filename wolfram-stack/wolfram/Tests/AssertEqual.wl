WF`AssertEqual[actual_,expected_,label_String] := If[SameQ[actual,expected],True,(Print["FAIL: ",label," actual=",InputForm[actual]," expected=",InputForm[expected]];False)]
