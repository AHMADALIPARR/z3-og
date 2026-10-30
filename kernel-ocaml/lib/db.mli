(* z3-og -- hand-rolled SMT stack. Copyright (c) 2026 Nova Parr, Ahmad Ali Parr, and Team HoloTwinKitty.
   Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
   LICENSE v1.0 -- see LICENSE at the repository root. Commercial
   exploitation requires separate written authorisation; publication,
   access, download, visibility, or possession is not authorisation. *)
(** An append-only, hash-chained assertion log: the ledger of the
    z3-og kernel.

    Each line of the file is one record:

      [hash <TAB> prev_hash <TAB> printed term]

    where the hashes are 16 lowercase hex digits.  The chain rule is

      [hash_i = chain_hash prev_hash_i term_i]
      [prev_hash_0 = 0],  [prev_hash_i = hash_{i-1}] for [i > 0].

    [chain_hash] is a self-contained FNV-1a 64-bit hash over the
    previous hash (rendered as hex) and the term's canonical printed
    form.  This is an {e integrity chain}, not a cryptographic one:
    it detects accidental corruption and casual tampering of the log
    file, and it totally orders the assertions.  Cryptographic
    anchoring of the chain head is the job of the C crypto module of
    the stack, not of this OCaml kernel package. *)

(** One ledger record, as loaded from disk. *)
type record =
  { index : int          (** 0-based position in the file *)
  ; term : string        (** the asserted term, in printed form *)
  ; prev_hash : int64
  ; hash : int64
  }

(** A ledger open for appending. *)
type t

(** [create path] creates a new, empty ledger at [path]
    (truncating any existing file) and opens it for appending. *)
val create : string -> t

(** [append ledger term] appends [term] as the next record,
    computing its chain hash from the current chain head, and
    flushes the record to disk before returning. *)
val append : t -> Term.term -> unit

(** [close ledger] flushes and closes the underlying file. *)
val close : t -> unit

(** [size ledger] is the number of records appended so far
    through this handle. *)
val size : t -> int

(** [head ledger] is the chain hash of the most recent record
    appended through this handle ([0L] if none). *)
val head : t -> int64

(** [chain_hash prev term_printed] is the FNV-1a 64-bit chain hash
    of one record, as described above. *)
val chain_hash : int64 -> string -> int64

(** [load path] reads and fully verifies the ledger at [path].
    Returns [Ok records] with every record in order, or
    [Error i] where [i] is the index of the first record that is
    malformed, whose [prev_hash] does not continue the chain, or
    whose stored hash does not match the recomputed chain hash. *)
val load : string -> (record list, int) result

(** [verify path] is [Ok n] if the ledger at [path] verifies and
    contains [n] records, and [Error i] with the index of the first
    bad record otherwise. *)
val verify : string -> (int, int) result
