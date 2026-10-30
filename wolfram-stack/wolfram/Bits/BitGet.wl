(*
 * z3-og -- hand-rolled SMT stack (clean-room remake in the original
 * Z3 architecture). Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
 * Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
 * LICENSE v1.0 -- see LICENSE at the repository root. Commercial
 * exploitation requires separate written authorisation; publication,
 * access, download, visibility, or possession is not authorisation.
 *)
WF`BitGet[words_List,i_Integer] /; i>=0&&Quotient[i,64]<Length[words] := BitAnd[BitShiftRight[words[[Quotient[i,64]+1]],Mod[i,64]],1]
WF`BitGet[_,_]:=$Failed
