// z3-og -- hand-rolled SMT stack (clean-room remake in the original
// Z3 architecture). Copyright (c) 2026 Ahmad Ali Parr.
// Licensed under the Sovereign Leviathan / SNAPKITTY OPAQUE SOURCE
// LICENSE v1.0 -- see LICENSE at the repository root. Commercial
// exploitation requires separate written authorisation; publication,
// access, download, visibility, or possession is not authorisation.
#![no_std]

pub type VarId = u32;
pub type LitId = u32; // Encodes variable + polarity (e.g., lit << 1 | sign)
pub type ClauseId = u32;

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum LitState {
    False = 0,
    True = 1,
    Unassigned = 2,
}

#[derive(Copy, Clone, Debug)]
pub struct ClauseRef {
    pub offset: usize,
    pub len: u32,
}

pub struct SatArena {
    // Flat storage for all clause literals
    pub literals: [LitId; 1_048_576],
    pub lit_cursor: usize,

    // Metadata for clauses
    pub clauses: [ClauseRef; 65_536],
    pub clause_count: usize,

    // Watch lists: maps a literal to the clause IDs watching it
    pub watches: [[ClauseId; 256]; 65_536],
    pub watch_counts: [usize; 65_536],

    // Variable assignments and decision tracking
    pub assignments: [LitState; 32_768],
    pub trail: [LitId; 32_768],
    pub trail_cursor: usize,

    // Antecedents for conflict analysis (clause that implied this assignment)
    pub antecedents: [Option<ClauseId>; 32_768],
}

impl SatArena {
    /// Propagates recent assignments using Two-Watched-Literals.
    /// Returns `Err(ConflictingClauseId)` if a conflict is detected.
    pub fn propagate(&mut self) -> Result<(), ClauseId> {
        while self.trail_cursor < self.trail.len() {
            let p = self.trail[self.trail_cursor];
            self.trail_cursor += 1;

            // The negation of p becomes false
            let false_lit = p ^ 1;

            // Inspect all clauses watching `false_lit`
            let mut i = 0;
            while i < self.watch_counts[false_lit as usize] {
                let c_id = self.watches[false_lit as usize][i];
                let clause = self.clauses[c_id as usize];
                let clause_lits = &mut self.literals[clause.offset..clause.offset + clause.len() as usize];

                // Ensure the watched literal is at index 1
                if clause_lits[0] == false_lit {
                    clause_lits.swap(0, 1);
                }

                let lead_lit = clause_lits[0];

                // If the other watched literal (index 0) is true, the clause is satisfied
                if self.get_lit_state(lead_lit) == LitState::True {
                    i += 1;
                    continue;
                }

                // Look for a new literal to watch
                let mut found_new_watch = false;
                for j in 2..clause_lits.len() {
                    if self.get_lit_state(clause_lits[j]) != LitState::False {
                        clause_lits.swap(1, j);
                        let new_watch = clause_lits[1];

                        // Remove from current watch list and add to new watch list
                        self.remove_watch(false_lit, c_id, i);
                        self.add_watch(new_watch, c_id);

                        found_new_watch = true;
                        break;
                    }
                }

                if found_new_watch {
                    continue; // Skip incrementing `i` because vector length shrank at index `i`
                }

                // No new watch found: lead_lit must be unit-propagated or we have a conflict
                if self.get_lit_state(lead_lit) == LitState::False {
                    // Conflict detected!
                    return Err(c_id);
                }

                // Unit propagation
                self.assign(lead_lit, Some(c_id));
                i += 1;
            }
        }
        Ok(())
    }

    #[inline(always)]
    pub fn get_lit_state(&self, lit: LitId) -> LitState {
        let var = lit >> 1;
        let state = self.assignments[var as usize];
        if (lit & 1) == 0 {
            state // Positive literal
        } else {
            // Negative literal flips state
            match state {
                LitState::True => LitState::False,
                LitState::False => LitState::True,
                LitState::Unassigned => LitState::Unassigned,
            }
        }
    }

    #[inline(always)]
    fn assign(&mut self, lit: LitId, antecedent: Option<ClauseId>) {
        let var = lit >> 1;
        let sign = (lit & 1) as u8;

        self.assignments[var as usize] = if sign == 0 { LitState::True } else { LitState::False };
        self.trail[self.trail_cursor] = lit;
        self.antecedents[var as usize] = antecedent;
    }

    #[inline(always)]
    fn remove_watch(&mut self, lit: LitId, c_id: ClauseId, index: usize) {
        let count = &mut self.watch_counts[lit as usize];
        let watches = &mut self.watches[lit as usize];
        watches[index] = watches[*count - 1];
        *count -= 1;
    }

    #[inline(always)]
    fn add_watch(&mut self, lit: LitId, c_id: ClauseId) {
        let count = self.watch_counts[lit as usize];
        self.watches[lit as usize][count] = c_id;
        self.watch_counts[lit as usize] += 1;
    }
}
