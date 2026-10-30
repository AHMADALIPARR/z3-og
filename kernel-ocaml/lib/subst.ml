module M = Map.Make (String)

type t = Term.term M.t

type error =
  | Occurs of string
  | Conflict of string

let empty = M.empty

let string_of_error = function
  | Occurs x -> "occurs check failed: variable " ^ x ^ " occurs in its binding"
  | Conflict x -> "conflicting binding for variable " ^ x

let rec occurs x t =
  match Term.node t with
  | Term.Var (y, _) -> x = y
  | Term.Const _ | Term.ConstInt _ -> false
  | _ -> List.exists (occurs x) (Term.children t)

let bind x term subst =
  if occurs x term then Error (Occurs x)
  else
    match M.find_opt x subst with
    | None -> Ok (M.add x term subst)
    | Some existing ->
        if Term.equal existing term then Ok subst else Error (Conflict x)

let of_list bindings =
  List.fold_left
    (fun acc (x, term) ->
      match acc with
      | Error _ as e -> e
      | Ok subst -> bind x term subst)
    (Ok empty) bindings

let lookup x subst = M.find_opt x subst

let bindings subst = M.bindings subst

let rec apply subst t =
  match Term.node t with
  | Term.Var (x, _) ->
      (match M.find_opt x subst with
       | None -> t
       | Some bound -> apply subst bound)
  | Term.Const _ | Term.ConstInt _ -> t
  | Term.App (fname, result_sort, args) ->
      Term.app fname result_sort (List.map (apply subst) args)
  | Term.Eq (a, b) -> Term.eq (apply subst a) (apply subst b)
  | Term.And (a, b) -> Term.and_ (apply subst a) (apply subst b)
  | Term.Not a -> Term.not_ (apply subst a)
  | Term.Add (a, b) -> Term.add (apply subst a) (apply subst b)
  | Term.Mul (a, b) -> Term.mul (apply subst a) (apply subst b)
  | Term.Lt (a, b) -> Term.lt (apply subst a) (apply subst b)
