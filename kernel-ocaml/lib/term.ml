type sort =
  | Bool
  | Int
  | Uninterpreted of string

type node =
  | Var of string * sort
  | Const of string * sort
  | ConstInt of int
  | App of string * sort * term list
  | Eq of term * term
  | And of term * term
  | Not of term
  | Add of term * term
  | Mul of term * term
  | Lt of term * term

and term =
  { id : int
  ; node : node
  ; sort : sort
  ; hash : int
  }

let node t = t.node
let sort_of t = t.sort
let id t = t.id
let hash t = t.hash
let equal a b = a.id = b.id
let compare a b = Int.compare a.id b.id

let string_of_sort = function
  | Bool -> "Bool"
  | Int -> "Int"
  | Uninterpreted name -> name

(* ------------------------------------------------------------------ *)
(* Hash-consing.                                                      *)
(*                                                                    *)
(* A [key] is a node with every subterm replaced by its identifier.   *)
(* Keys contain only strings, integers, sorts and lists thereof, so   *)
(* structural hashing and equality on keys are exact.  The table      *)
(* maps each key to the unique term built for it.                     *)
(* ------------------------------------------------------------------ *)

type key =
  | KVar of string * sort
  | KConst of string * sort
  | KConstInt of int
  | KApp of string * sort * int list
  | KEq of int * int
  | KAnd of int * int
  | KNot of int
  | KAdd of int * int
  | KMul of int * int
  | KLt of int * int

let table : (key, term) Hashtbl.t = Hashtbl.create 1024
let next_id = ref 0

let intern key build_node sort =
  match Hashtbl.find_opt table key with
  | Some t -> t
  | None ->
      let t = { id = !next_id; node = build_node; sort; hash = Hashtbl.hash key } in
      incr next_id;
      Hashtbl.add table key t;
      t

let require_sort who expected t =
  if t.sort <> expected then
    invalid_arg
      (Printf.sprintf "Term.%s: expected sort %s, got %s" who
         (string_of_sort expected) (string_of_sort t.sort))

let var name sort = intern (KVar (name, sort)) (Var (name, sort)) sort

let const name sort = intern (KConst (name, sort)) (Const (name, sort)) sort

let const_int n = intern (KConstInt n) (ConstInt n) Int

let app fname result_sort args =
  let key = KApp (fname, result_sort, List.map id args) in
  intern key (App (fname, result_sort, args)) result_sort

let eq a b =
  if a.sort <> b.sort then
    invalid_arg
      (Printf.sprintf "Term.eq: sort mismatch (%s vs %s)"
         (string_of_sort a.sort) (string_of_sort b.sort));
  intern (KEq (a.id, b.id)) (Eq (a, b)) Bool

let and_ a b =
  require_sort "and_" Bool a;
  require_sort "and_" Bool b;
  intern (KAnd (a.id, b.id)) (And (a, b)) Bool

let not_ a =
  require_sort "not_" Bool a;
  intern (KNot a.id) (Not a) Bool

let add a b =
  require_sort "add" Int a;
  require_sort "add" Int b;
  intern (KAdd (a.id, b.id)) (Add (a, b)) Int

let mul a b =
  require_sort "mul" Int a;
  require_sort "mul" Int b;
  intern (KMul (a.id, b.id)) (Mul (a, b)) Int

let lt a b =
  require_sort "lt" Int a;
  require_sort "lt" Int b;
  intern (KLt (a.id, b.id)) (Lt (a, b)) Bool

let children t =
  match t.node with
  | Var _ | Const _ | ConstInt _ -> []
  | App (_, _, args) -> args
  | Eq (a, b) | And (a, b) | Add (a, b) | Mul (a, b) | Lt (a, b) -> [ a; b ]
  | Not a -> [ a ]

let subterms t =
  let seen = Hashtbl.create 32 in
  let acc = ref [] in
  let rec visit u =
    if not (Hashtbl.mem seen u.id) then begin
      Hashtbl.add seen u.id ();
      acc := u :: !acc;
      List.iter visit (children u)
    end
  in
  visit t;
  List.rev !acc

let rec to_string t =
  match t.node with
  | Var (name, _) -> "?" ^ name
  | Const (name, _) -> name
  | ConstInt n -> string_of_int n
  | App (fname, _, args) ->
      "(" ^ String.concat " " (fname :: List.map to_string args) ^ ")"
  | Eq (a, b) -> "(= " ^ to_string a ^ " " ^ to_string b ^ ")"
  | And (a, b) -> "(and " ^ to_string a ^ " " ^ to_string b ^ ")"
  | Not a -> "(not " ^ to_string a ^ ")"
  | Add (a, b) -> "(+ " ^ to_string a ^ " " ^ to_string b ^ ")"
  | Mul (a, b) -> "(* " ^ to_string a ^ " " ^ to_string b ^ ")"
  | Lt (a, b) -> "(< " ^ to_string a ^ " " ^ to_string b ^ ")"
