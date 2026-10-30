(** Substitutions: finite maps from variables to terms.

    A substitution is built incrementally with {!bind}.  Binding is
    checked: a variable may not be bound to a term in which it occurs
    (occurs check), and it may not be re-bound to a different term
    (consistency check).  Because every binding passes the occurs
    check, the binding graph is acyclic and {!apply} always
    terminates. *)

(** A substitution. *)
type t

(** Reasons a binding can be rejected. *)
type error =
  | Occurs of string
      (** the variable occurs in the term it would be bound to *)
  | Conflict of string
      (** the variable is already bound to a different term *)

val empty : t

(** [bind x term subst] binds variable [x] to [term].
    Returns [Error (Occurs x)] if [x] occurs in [term],
    [Error (Conflict x)] if [x] is already bound to a term that is
    not structurally equal to [term], and [Ok subst'] otherwise.
    Re-binding [x] to an equal term is accepted and changes nothing. *)
val bind : string -> Term.term -> t -> (t, error) result

(** [of_list bindings] folds {!bind} over [bindings] left to right. *)
val of_list : (string * Term.term) list -> (t, error) result

(** [lookup x subst] is the term bound to [x], if any. *)
val lookup : string -> t -> Term.term option

(** [bindings subst] is the list of (variable, term) pairs. *)
val bindings : t -> (string * Term.term) list

(** [occurs x term] is [true] iff the variable [x] occurs in [term]. *)
val occurs : string -> Term.term -> bool

(** [apply subst term] simultaneously substitutes every bound
    variable in [term].  Bound terms are themselves substituted
    (bindings are chased), so the result contains no bound variable.
    The result is hash-consed, hence canonical. *)
val apply : t -> Term.term -> Term.term

val string_of_error : error -> string
