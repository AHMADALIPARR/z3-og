/// Builds a symbolic XOR-based stencil for elementary cellular automata transition rules
pub fn build_wolfram_stencil(
    sym: &mut SymbolicArena,
    left: ExprId,
    curr: ExprId,
    right: ExprId,
) -> ExprId {
    // Example: Rule logic decomposed into XOR/AND standard forms
    let l_xor_r = sym.alloc(ExprOp::Xor(left, right));
    sym.alloc(ExprOp::Xor(curr, l_xor_r))
}
