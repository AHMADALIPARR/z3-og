WF`WordsFor[cells_Integer] /; cells>=0 := Quotient[cells,64]+Boole[Mod[cells,64]!=0]
WF`WordsFor[_]:=$Failed
