# z3og_kernel — hand-rolled OCaml trusted kernel for the z3-og stack.
#
# This Makefile is the verified build path on machines without dune:
# it compiles the library with plain ocamlc in dependency order
# (term -> subst -> checker -> db -> test) and links the test
# executable.  On machines with dune, the shipped dune-project /
# *.opam / dune files describe the same package (layout mirrors the
# sqlite3-ocaml fork: dune-project + <pkg>.opam at the package root,
# library in lib/, tests in test/).

OCAMLC ?= ocamlc
LIB := lib
TEST := test

LIB_CMIS := $(LIB)/term.cmi $(LIB)/subst.cmi $(LIB)/checker.cmi $(LIB)/db.cmi
LIB_CMOS := $(LIB)/term.cmo $(LIB)/subst.cmo $(LIB)/checker.cmo $(LIB)/db.cmo

.PHONY: all test clean

all: test_kernel

$(LIB)/term.cmi: $(LIB)/term.mli
	$(OCAMLC) -c $(LIB)/term.mli

$(LIB)/term.cmo: $(LIB)/term.ml $(LIB)/term.cmi
	$(OCAMLC) -c -I $(LIB) $(LIB)/term.ml

$(LIB)/subst.cmi: $(LIB)/subst.mli $(LIB)/term.cmi
	$(OCAMLC) -c -I $(LIB) $(LIB)/subst.mli

$(LIB)/subst.cmo: $(LIB)/subst.ml $(LIB)/subst.cmi
	$(OCAMLC) -c -I $(LIB) $(LIB)/subst.ml

$(LIB)/checker.cmi: $(LIB)/checker.mli $(LIB)/term.cmi
	$(OCAMLC) -c -I $(LIB) $(LIB)/checker.mli

$(LIB)/checker.cmo: $(LIB)/checker.ml $(LIB)/checker.cmi
	$(OCAMLC) -c -I $(LIB) $(LIB)/checker.ml

$(LIB)/db.cmi: $(LIB)/db.mli $(LIB)/term.cmi
	$(OCAMLC) -c -I $(LIB) $(LIB)/db.mli

$(LIB)/db.cmo: $(LIB)/db.ml $(LIB)/db.cmi
	$(OCAMLC) -c -I $(LIB) $(LIB)/db.ml

$(TEST)/test_kernel.cmo: $(TEST)/test_kernel.ml $(LIB_CMIS)
	$(OCAMLC) -c -I $(LIB) $(TEST)/test_kernel.ml

test_kernel: $(LIB_CMOS) $(TEST)/test_kernel.cmo
	$(OCAMLC) -o $@ $(LIB_CMOS) $(TEST)/test_kernel.cmo

test: test_kernel
	./test_kernel

clean:
	rm -f $(LIB)/*.cmi $(LIB)/*.cmo $(LIB)/*.cmx $(LIB)/*.o \
	      $(TEST)/*.cmi $(TEST)/*.cmo $(TEST)/*.cmx $(TEST)/*.o \
	      test_kernel
