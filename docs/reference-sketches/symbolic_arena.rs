#![no_std]

pub type ExprId = u32;

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum ExprOp {
    Const(bool),
    Var(u32),          // Represents a bit at a specific array index and time step
    Not(ExprId),
    And(ExprId, ExprId),
    Or(ExprId, ExprId),
    Xor(ExprId, ExprId),
}

pub struct SymbolicArena {
    pub exprs: [ExprOp; 16_384],
    pub expr_count: usize,
}

impl SymbolicArena {
    pub fn new() -> Self {
        Self {
            exprs: [ExprOp::Const(false); 16_384],
            expr_count: 0,
        }
    }

    #[inline(always)]
    pub fn alloc(&mut self, op: ExprOp) -> ExprId {
        let id = self.expr_count as ExprId;
        self.exprs[id as usize] = op;
        self.expr_count += 1;
        id
    }
}
