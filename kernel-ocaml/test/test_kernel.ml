(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
   Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
   LICENSE v1.0 -- see LICENSE at the repository root. Commercial
   exploitation requires separate written authorisation; publication,
   access, download, visibility, or possession is not authorisation. *)
(* Test suite for the z3-og OCaml trusted kernel.
   Prints one PASS/FAIL line per check and exits non-zero if any
   check failed. *)

(* The library is built unwrapped (see lib/dune), so its modules
   Term, Subst, Checker and Db are used directly. *)

let failures = ref 0
let total = ref 0

let check name cond =
  incr total;
  if cond then Printf.printf "PASS %s\n%!" name
  else begin
    incr failures;
    Printf.printf "FAIL %s\n%!" name
  end

let u = Term.Uninterpreted "U"

(* ------------------------------------------------------------------ *)
(* 1. Hash-consing: physical equality of structurally equal terms     *)
(* ------------------------------------------------------------------ *)

let test_hash_consing () =
  let a1 = Term.const "a" u in
  let a2 = Term.const "a" u in
  check "hashcons: separately built constants are physically equal" (a1 == a2);
  let fa1 = Term.app "f" u [ a1 ] in
  let fa2 = Term.app "f" u [ a2 ] in
  check "hashcons: separately built applications are physically equal"
    (fa1 == fa2);
  let ga1 = Term.app "g" Term.Int [ a1 ] in
  let ga2 = Term.app "g" Term.Int [ a2 ] in
  let e1 = Term.eq ga1 (Term.const_int 42) in
  let e2 = Term.eq ga2 (Term.const_int 42) in
  check "hashcons: separately built equalities are physically equal" (e1 == e2);
  check "hashcons: integer literals are physically equal"
    (Term.const_int 7 == Term.const_int 7);
  let different = Term.app "g" u [ a1 ] in
  check "hashcons: different terms are not physically equal" (fa1 != different);
  check "hashcons: printed form is canonical"
    (Term.to_string e1 = "(= (g a) 42)")

(* ------------------------------------------------------------------ *)
(* 2. Substitution: apply, chasing, occurs check, conflict check      *)
(* ------------------------------------------------------------------ *)

let expect_ok name = function
  | Ok v -> v
  | Error e ->
      check name false;
      Printf.printf "       unexpected error: %s\n%!" (Subst.string_of_error e);
      Subst.empty

let test_subst () =
  let x = Term.var "x" Term.Int in
  let five = Term.const_int 5 in
  let s = expect_ok "subst: bind x := 5 succeeds" (Subst.bind "x" five Subst.empty) in
  let applied = Subst.apply s (Term.add x (Term.const_int 1)) in
  check "subst: apply substitutes under a constructor"
    (applied == Term.add five (Term.const_int 1));
  check "subst: unbound variable is left alone"
    (Subst.apply s (Term.var "z" Term.Int) == Term.var "z" Term.Int);
  (* Chained bindings: y := x, x := 5, so y maps to 5. *)
  let y = Term.var "y" Term.Int in
  let s2 =
    expect_ok "subst: chained bindings build"
      (Subst.of_list [ ("y", x); ("x", five) ])
  in
  check "subst: apply chases chained bindings" (Subst.apply s2 y == five);
  (* Occurs check: x := f(x) must be rejected. *)
  let xu = Term.var "x" u in
  let occurs_result = Subst.bind "x" (Term.app "f" u [ xu ]) Subst.empty in
  check "subst: occurs check rejects x := f(x)"
    (match occurs_result with Error (Subst.Occurs "x") -> true | _ -> false);
  check "subst: occurs predicate finds the variable"
    (Subst.occurs "x" (Term.app "f" u [ xu ])
     && not (Subst.occurs "x" (Term.const "a" u)));
  (* Consistency: re-binding to a different term is rejected,
     re-binding to an equal term is accepted. *)
  check "subst: conflicting re-binding is rejected"
    (match Subst.bind "x" (Term.const_int 6) s with
     | Error (Subst.Conflict "x") -> true
     | _ -> false);
  check "subst: equal re-binding is accepted"
    (match Subst.bind "x" five s with Ok _ -> true | Error _ -> false)

(* ------------------------------------------------------------------ *)
(* 3. Congruence closure: consequences, non-consequences, disequality *)
(* ------------------------------------------------------------------ *)

let test_checker () =
  let a = Term.const "a" u in
  let b = Term.const "b" u in
  let c = Term.const "c" u in
  let k = Term.const "k" u in
  let f t = Term.app "f" u [ t ] in
  let g t = Term.app "g" u [ t ] in
  let chain = [ Term.eq a b; Term.eq b c ] in
  check "checker: transitivity chain a = c"
    (Checker.entails_eq chain a c);
  check "checker: congruence consequence f(a) = f(c) from a = b = c"
    (Checker.entails_eq chain (f a) (f c));
  check "checker: congruence consequence f(a) = f(b) from a = b"
    (Checker.entails_eq chain (f a) (f b));
  check "checker: non-consequence f(a) = g(a) is rejected"
    (not (Checker.entails_eq chain (f a) (g a)));
  check "checker: non-consequence a = k is rejected"
    (not (Checker.entails_eq chain a k));
  check "checker: nested congruence f(f(a)) = f(f(c))"
    (Checker.entails_eq chain (f (f a)) (f (f c)));
  (* Disequality transported across a congruence class. *)
  let with_diseq = [ Term.eq a b; Term.not_ (Term.eq (f a) k) ] in
  check "checker: disequality f(b) <> k transported from f(a) <> k, a = b"
    (Checker.entails_diseq with_diseq (f b) k);
  check "checker: equal terms are not disequal"
    (not (Checker.entails_diseq with_diseq (f a) (f b)));
  check "checker: mere class difference is not a disequality proof"
    (not (Checker.entails_diseq chain a k));
  (* Integer literals. *)
  check "checker: distinct numerals are disequal"
    (Checker.entails_diseq [] (Term.const_int 1) (Term.const_int 2));
  check "checker: a numeral is not disequal to itself"
    (not (Checker.entails_diseq [] (Term.const_int 1) (Term.const_int 1)));
  (* Consistency of assumption sets. *)
  check "checker: plain equalities are consistent" (Checker.consistent chain);
  check "checker: a = b together with a <> b is inconsistent"
    (not (Checker.consistent [ Term.eq a b; Term.not_ (Term.eq a b) ]))

(* ------------------------------------------------------------------ *)
(* 4. The hash-chained assertion ledger                               *)
(* ------------------------------------------------------------------ *)

let read_all path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

let write_all path content =
  let oc = open_out_bin path in
  output_string oc content;
  close_out oc

(* Flip the first character of the term field of the second record
   (index 1) to a different character. *)
let tamper_second_record content =
  let bytes = Bytes.of_string content in
  let first_nl = String.index content '\n' in
  let line2 = first_nl + 1 in
  let tab1 = String.index_from content line2 '\t' in
  let tab2 = String.index_from content (tab1 + 1) '\t' in
  let pos = tab2 + 1 in
  let ch = Bytes.get bytes pos in
  Bytes.set bytes pos (if ch = 'X' then 'Y' else 'X');
  Bytes.to_string bytes

let test_db () =
  let a = Term.const "a" u in
  let b = Term.const "b" u in
  let t1 = Term.eq a b in
  let t2 = Term.app "f" u [ a ] in
  let t3 = Term.add (Term.const_int 1) (Term.const_int 2) in
  let path = Filename.temp_file "z3og_ledger" ".log" in
  let ledger = Db.create path in
  Db.append ledger t1;
  Db.append ledger t2;
  Db.append ledger t3;
  check "db: size after 3 appends is 3" (Db.size ledger = 3);
  let head_before_close = Db.head ledger in
  Db.close ledger;
  check "db: verify passes on the written ledger" (Db.verify path = Ok 3);
  (match Db.load path with
   | Ok records ->
       check "db: load returns 3 records" (List.length records = 3);
       let r0 = List.nth records 0 and r1 = List.nth records 1 in
       let r2 = List.nth records 2 in
       check "db: record 0 holds the first asserted term"
         (r0.Db.term = Term.to_string t1);
       check "db: record 0 starts the chain at prev_hash 0"
         (r0.Db.prev_hash = 0L);
       check "db: chain links line up (record 1 prev = record 0 hash)"
         (r1.Db.prev_hash = r0.Db.hash);
       check "db: chain head matches the ledger head"
         (r2.Db.hash = head_before_close);
       check "db: stored hash equals recomputed chain hash"
         (r1.Db.hash = Db.chain_hash r1.Db.prev_hash r1.Db.term)
   | Error i ->
       check
         (Printf.sprintf "db: load unexpectedly failed at record %d" i)
         false);
  (* Tamper case: a byte flipped in the second record of a copy
     must be detected at exactly that record. *)
  let tampered_path = Filename.temp_file "z3og_ledger_tampered" ".log" in
  write_all tampered_path (tamper_second_record (read_all path));
  check "db: tampered copy fails verification at record 1"
    (Db.verify tampered_path = Error 1);
  Sys.remove path;
  Sys.remove tampered_path

let () =
  test_hash_consing ();
  test_subst ();
  test_checker ();
  test_db ();
  Printf.printf "----\n%d checks, %d failed\n%!" !total !failures;
  if !failures > 0 then exit 1
