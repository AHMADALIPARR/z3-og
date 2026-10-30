WF`HexWords[words_List] /; VectorQ[words,IntegerQ[#]&&0<=#<2^64&] := StringRiffle[IntegerString[#,16,16]&/@words,","]
WF`HexWords[_]:=$Failed
