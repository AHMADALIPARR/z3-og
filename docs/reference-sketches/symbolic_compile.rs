impl SymbolicArena {
    /// Compiles a symbolic expression graph into CNF clauses pushed directly into the SatArena.
    pub fn compile_to_cnf(
        &self,
        root: ExprId,
        sat: &mut crate::SatArena,
    ) -> u32 /* returns root literal */ {
        // Flat-array memoization table for Tseitin variables
        let mut tseitin_map: [Option<u32>; 16_384] = [None; 16_384];
        self.tseitin_rec(root, &mut tseitin_map, sat)
    }

    fn tseitin_rec(
        &self,
        id: ExprId,
        map: &mut [Option<u32>; 16_384],
        sat: &mut crate::SatArena,
    ) -> u32 {
        if let Some(lit) = map[id as usize] {
            return lit;
        }

        let lit = match self.exprs[id as usize] {
            ExprOp::Const(true) => {
                // True literal: add unit clause (l)
                let l = sat.alloc_var() << 1;
                sat.add_clause(&[l]);
                l
            }
            ExprOp::Const(false) => {
                // False literal: add unit clause (~l)
                let l = (sat.alloc_var() << 1) | 1;
                sat.add_clause(&[l]);
                l
            }
            ExprOp::Var(v) => {
                // Map symbolic array variable directly to a SAT variable literal
                (v * 2)
            }
            ExprOp::Not(inner) => {
                let in_lit = self.tseitin_rec(inner, map, sat);
                in_lit ^ 1 // Flip polarity
            }
            ExprOp::And(lhs, rhs) => {
                let l1 = self.tseitin_rec(lhs, map, sat);
                let l2 = self.tseitin_rec(rhs, map, sat);
                let out_var = sat.alloc_var();
                let out_lit = out_var << 1;

                // Tseitin clauses for AND: (l1 ∨ ¬out) ∧ (l2 ∨ ¬out) ∧ (¬l1 ∨ ¬l2 ∨ out)
                sat.add_clause(&[l1 ^ 1, out_lit]);
                sat.add_clause(&[l2 ^ 1, out_lit]);
                sat.add_clause(&[l1, l2, out_lit ^ 1]);

                out_lit
            }
            ExprOp::Xor(lhs, rhs) => {
                let l1 = self.tseitin_rec(lhs, map, sat);
                let l2 = self.tseitin_rec(rhs, map, sat);
                let out_var = sat.alloc_var();
                let out_lit = out_var << 1;

                // Tseitin clauses for XOR (Wolfram rule stencils heavy use):
                // (¬l1 ∨ ¬l2 ∨ ¬out) ∧ (l1 ∨ l2 ∨ ¬out) ∧ (l1 ∨ ¬l2 ∨ out) ∧ (¬l1 ∨ l2 ∨ out)
                sat.add_clause(&[l1 ^ 1, l2 ^ 1, out_lit ^ 1]);
                sat.add_clause(&[l1, l2, out_lit ^ 1]);
                sat.add_clause(&[l1, l2 ^ 1, out_lit]);
                sat.add_clause(&[l1 ^ 1, l2, out_lit]);

                out_lit
            }
            ExprOp::Or(_, _) => {
                // Dual of AND / De Morgan's application
                todo!("Implement OR compilation")
            }
        };

        map[id as usize] = Some(lit);
        lit
    }
}
