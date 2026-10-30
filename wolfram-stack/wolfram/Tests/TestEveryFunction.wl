(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`TestEveryFunction[] := Module[{a,b,c,tests},
 a=<|"Shape"->{2,2},"Data"->{1,2,3,4}|>;
 b=WF`FlatSet[a,{2,1},9];
 c=WF`FlatCreate[{2,3},7];
 tests={
 WF`AssertEqual[WF`ValidateBits[{0,1,0}],True,"validate bits"],
 WF`AssertEqual[WF`ValidateShape[{2,3}],True,"validate shape"],
 WF`AssertEqual[WF`ShapeSize[{2,3}],6,"shape size"],
 WF`AssertEqual[WF`FlatValid[a],True,"flat valid"],
 WF`AssertEqual[WF`FlatGet[a,{2,1}],3,"flat get"],
 WF`AssertEqual[WF`FlatGet[b,{2,1}],9,"flat set"],
 WF`AssertEqual[Length[c["Data"]],6,"flat create"],
 WF`AssertEqual[WF`FlatReshape[a,{4}]["Shape"],{4},"reshape"],
 WF`AssertEqual[WF`FlatTranspose2D[a]["Data"],{1,3,2,4},"transpose"],
 WF`AssertEqual[WF`Map2Flat[Plus,{1,2},{3,4}],{4,6},"map2"],
 WF`AssertEqual[WF`SliceFlat[{1,2,3,4},4,2,-2],{4,2},"slice"],
 WF`AssertEqual[WF`RotateFlat[{1,2,3},1],{3,1,2},"rotate"],
 WF`AssertEqual[WF`ReverseFlat[{1,2,3}],{3,2,1},"reverse"],
 WF`AssertEqual[WF`PrefixSum[{4,5,6}],{4,9,15},"prefix sum"],
 WF`AssertEqual[WF`HistogramFlat[{2,3,2,4},2,4],{2,1,1},"histogram"],
 WF`AssertEqual[WF`Stencil2D[{1,2,3,4},2,2,{{1}}],{1,2,3,4},"stencil2d"],
 WF`AssertEqual[WF`BitGet[{13},2],1,"bitget"],
 WF`AssertEqual[WF`WordsFor[65],2,"wordsfor"],
 WF`AssertEqual[WF`BitNotWidth[5,4],10,"bitnotwidth"],
 WF`AssertEqual[WF`ShiftPacked[{1},4,1],{2},"shiftpacked"],
 WF`AssertEqual[WF`AndPacked[{15},{10},4],{10},"andpacked"],
 WF`AssertEqual[WF`RuleBit[90,0,0,1],1,"rulebit"],
 WF`AssertEqual[Length[WF`ElementaryEvolve[{0,1,0},90,3]],4,"evolve"],
 WF`AssertEqual[Length[WF`ElementarySpaceTime[{0,1,0},90,3]],12,"spacetime"],
 WF`AssertEqual[WF`LifeCount[ConstantArray[0,4],2,2,1,1],0,"lifecount"],
 WF`AssertEqual[WF`TotalisticStep[{0,1,0},{0,1,1,1},1],{1,1,1},"totalistic"],
 WF`AssertEqual[WF`RuleComposition[{0,1,0},{0}],{0,0,0},"composition"],
 WF`AssertEqual[WF`SumFlat[{1,2,3}],6,"sumflat"],
 WF`AssertEqual[WF`ProductFlat[{2,3,4}],24,"productflat"],
 WF`AssertEqual[WF`MinFlat[{3,1,4}],1,"minflat"],
 WF`AssertEqual[WF`MaxFlat[{3,1,4}],4,"maxflat"],
 WF`AssertEqual[WF`PrefixMin[{3,2,4,1}],{3,2,2,1},"prefixmin"],
 WF`AssertEqual[WF`PrefixMax[{3,2,4,1}],{3,3,4,4},"prefixmax"],
 WF`AssertEqual[WF`Neighbors1D[1,5,1],{1,2},"neighbors1d"],
 WF`AssertEqual[WF`Neighbors2D[1,1,2,2],{2,3,4},"neighbors2d"],
 WF`AssertEqual[WF`LinearShift[{1,2,3},1],{0,1,2},"linearshift"],
 WF`AssertEqual[WF`PeriodicIndex[0,5],5,"periodic"],
 WF`AssertEqual[WF`ReflectIndex[0,3],2,"reflect"],
 WF`AssertEqual[WF`ReflectShift[{1,2,3},1],{2,1,2},"reflectshift"],
 WF`AssertEqual[WF`HexWords[{1}],"0000000000000001","hexwords"],
 WF`AssertEqual[WF`ParseHexWords["0000000000000001"],{1},"parsehex"],
 WF`AssertEqual[WF`IntegerSqrt[99],9,"integer sqrt"],
 WF`AssertEqual[WF`ModPower[2,10,17],4,"modpower"],
 WF`AssertEqual[WF`IntegerLog2[1024],10,"log2"],
 WF`AssertEqual[WF`ExclusiveScan[Plus,0,{1,2,3}],{0,1,3},"exclusive scan"],
 WF`AssertEqual[WF`StableFilter[EvenQ,{1,2,3,4}],{2,4},"stable filter"],
 WF`AssertEqual[WF`BitRangeExtract[{13},1,3],{0,1,1},"bit extract"]
 };And@@tests]
