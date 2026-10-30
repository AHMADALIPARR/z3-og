(** Hash-consed first-order terms for the z3-og trusted kernel.

    Every term is built through the smart constructors in this module.
    Construction goes through a global hash-consing table, so two
    structurally equal terms are always the {e same} physical value:
    [t1 == t2] holds whenever [t1] and [t2] are structurally equal.
    Equality, hashing and ordering on terms are therefore all reduced
    to the unique integer identifier of each term. *)

(** Sorts of terms. *)
type sort =
  | Bool
  | Int
  | Uninterpreted of string

(** A hash-consed term.  Abstract: use the constructors below. *)
type term

(** The shape of a term.  Values of this type are only ever produced by
    the smart constructors below; pattern matching on them is safe. *)
type node =
  | Var of string * sort          (** a variable, substitutable *)
  | Const of string * sort        (** a constant symbol (nullary, rigid) *)
  | ConstInt of int               (** an integer literal *)
  | App of string * sort * term list
      (** application of a function symbol to arguments;
          the sort is the declared result sort of the symbol *)
  | Eq of term * term             (** equality, result sort [Bool] *)
  | And of term * term            (** conjunction, result sort [Bool] *)
  | Not of term                   (** negation, result sort [Bool] *)
  | Add of term * term            (** integer addition, result sort [Int] *)
  | Mul of term * term            (** integer multiplication, result [Int] *)
  | Lt of term * term             (** integer less-than, result [Bool] *)

(** [node t] is the shape of [t]. *)
val node : term -> node

(** [sort_of t] is the sort of [t], checked at construction time. *)
val sort_of : term -> sort

(** [id t] is the unique identifier of [t] in the hash-consing table.
    Structurally equal terms have the same identifier. *)
val id : term -> int

(** A cached structural hash of [t]. *)
val hash : term -> int

(** Physical/identifier equality on terms.  Equivalent to [( == )]. *)
val equal : term -> term -> bool

(** Total order on terms, by identifier. *)
val compare : term -> term -> int

(** {1 Smart constructors}

    Each constructor validates the sorts of its arguments and raises
    [Invalid_argument] on a sort mismatch. *)

val var : string -> sort -> term
val const : string -> sort -> term
val const_int : int -> term
val app : string -> sort -> term list -> term
val eq : term -> term -> term
val and_ : term -> term -> term
val not_ : term -> term
val add : term -> term -> term
val mul : term -> term -> term
val lt : term -> term -> term

(** [children t] is the list of immediate subterms of [t]
    (empty for variables, constants and literals). *)
val children : term -> term list

(** [subterms t] is [t] together with all of its transitive subterms,
    deduplicated by identifier, in pre-order. *)
val subterms : term -> term list

(** [to_string t] is the canonical printed form of [t]:
    variables print as [?name], constants as their name, integer
    literals in decimal, and compound terms in fully parenthesised
    prefix form with distinct operator tags, e.g. ["(= a b)"],
    ["(f a b)"], ["(+ ?x 3)"].  Names are expected to be
    identifier-like (no whitespace or parentheses); under that
    assumption the printed form uniquely determines the term.
    This printed form is what the assertion ledger hashes. *)
val to_string : term -> string

(** Human-readable name of a sort, e.g. for diagnostics. *)
val string_of_sort : sort -> string
