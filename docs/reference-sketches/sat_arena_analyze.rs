// z3-og -- hand-rolled SMT stack (clean-room remake in the original
// Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
// Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root. Commercial
// exploitation requires separate written authorisation; publication,
// access, download, visibility, or possession is not authorisation.
pub struct SatArena {
    // ... (previous fields: literals, clauses, watches, assignments, trail, antecedents)

    /// Tracks the decision level at which each variable was assigned
    pub levels: [u32; 32_768],

    /// Tracks variables processed during conflict analysis to avoid duplicate traversal
    pub seen: [bool; 32_768],

    /// Current search decision depth
    pub decision_level: u32,
}

impl SatArena {
    /// Analyzes a conflict using the 1UIP (First Unique Implication Point) scheme.
    /// Returns `(learned_clause_id, backtrack_level)`.
    pub fn analyze_conflict(&mut self, conflict_clause: ClauseId) -> Result<(ClauseId, u32), &'static str> {
        let mut path_c = 0;
        let mut p: Option<LitId> = None;
        let mut clause_to_examine = conflict_clause;

        let mut learned_lits: [LitId; 256] = [0; 256];
        let mut learned_len = 1; // Leave index 0 open for the 1UIP literal

        let current_level = self.decision_level;
        if current_level == 0 {
            return Err("Conflict at decision level 0: Unsat");
        }

        let mut index = self.trail_cursor;

        loop {
            let clause = self.clauses[clause_to_examine as usize];
            let lits = &self.literals[clause.offset..clause.offset + clause.len() as usize];

            // Skip the first literal if it's the one we just processed (antecedent check)
            let start_idx = if p.is_some() && lits[0] == p.unwrap() { 1 } else { 0 };

            for j in start_idx..lits.len() {
                let lit = lits[j];
                let var = lit >> 1;

                if !self.seen[var as usize] && self.levels[var as usize] > 0 {
                    self.seen[var as usize] = true;
                    if self.levels[var as usize] == current_level {
                        path_c += 1;
                    } else {
                        // Literals from lower levels go directly into the learned clause
                        if learned_len < learned_lits.len() {
                            learned_lits[learned_len] = lit;
                            learned_len += 1;
                        }
                    }
                }
            }

            // Select next literal to resolve from the trail (working backwards)
            loop {
                if index == 0 {
                    return Err("Exhausted trail during conflict analysis");
                }
                index -= 1;
                let next_lit = self.trail[index];
                let var = next_lit >> 1;
                if self.seen[var as usize] {
                    p = Some(next_lit);
                    self.seen[var as usize] = false;
                    break;
                }
            }

            path_c -= 1;
            if path_c == 0 {
                break; // Found the 1UIP!
            }

            // Retrieve antecedent clause for the next resolution step
            let var = p.unwrap() >> 1;
            match self.antecedents[var as usize] {
                Some(ant) => clause_to_examine = ant,
                None => return Err("Missing antecedent on trail variable"),
            }
        }

        // The 1UIP literal's negation goes at index 0 of the learned clause
        let uip_lit = p.unwrap() ^ 1;
        learned_lits[0] = uip_lit;

        // Compute backjump level (the second highest level in the learned clause)
        let mut backtrack_level = 0;
        for i in 1..learned_len {
            let lvl = self.levels[(learned_lits[i] >> 1) as usize];
            if lvl > backtrack_level {
                backtrack_level = lvl;
            }
        }

        // Commit learned clause to the arena
        let learned_clause_id = self.add_clause(&learned_lits[..learned_len]);

        // Reset `seen` flags for all processed literals
        for i in 0..learned_len {
            self.seen[(learned_lits[i] >> 1) as usize] = false;
        }

        Ok((learned_clause_id, backtrack_level))
    }

    #[inline(always)]
    fn add_clause(&mut self, lits: &[LitId]) -> ClauseId {
        let c_id = self.clause_count as ClauseId;
        let offset = self.lit_cursor;

        for (i, &lit) in lits.iter().enumerate() {
            self.literals[self.lit_cursor] = lit;
            self.lit_cursor += 1;
            if i < 2 {
                self.add_watch(lit, c_id);
            }
        }

        self.clauses[c_id as usize] = ClauseRef {
            offset,
            len: lits.len() as u32,
        };
        self.clause_count += 1;
        c_id
    }
}
