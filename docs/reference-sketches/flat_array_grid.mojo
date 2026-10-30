from sys import SIMD
from memory import Pointer

struct FlatArrayGrid:
    var cells: Pointer[UInt64]
    var next_cells: Pointer[UInt64]
    var word_count: Int

    fn __init__(inout self, word_count: Int):
        self.word_count = word_count
        self.cells = Pointer[UInt64].alloc(word_count)
        self.next_cells = Pointer[UInt64].alloc(word_count)

        # Zero-initialize memory arenas
        for i in range(word_count):
            self.cells.store(i, 0)
            self.next_cells.store(i, 0)

    fn __del__(owned self):
        self.cells.free()
        self.next_cells.free()

    fn set_centered_seed(self):
        # Place a single bit in the middle of the grid
        let mid = self.word_count // 2
        self.cells.store(mid, UInt64(1) << 32)

    @always_inline
    fn step_wolfram_rule(inout self, rule: UInt8):
        """
        Evaluates a 3-neighborhood Wolfram cellular automaton rule
        across the flat array using packed 64-bit word operations.
        """
        for i in range(self.word_count):
            let left = self.cells.load(i - 1) if i > 0 else UInt64(0)
            let curr = self.cells.load(i)
            let right = self.cells.load(i + 1) if i < self.word_count - 1 else UInt64(0)

            # Shift bits across word boundaries for 3-neighborhood overlap
            let l_neighbor = (curr << 1) | (left >> 63)
            let r_neighbor = (curr >> 1) | (right << 63)

            var word_res: UInt64 = 0

            # Unroll or evaluate neighborhood bits in parallel
            for bit in range(64):
                let mask = UInt64(1) << bit
                let l_bit = 4 if (l_neighbor & mask) != 0 else 0
                let c_bit = 2 if (curr & mask) != 0 else 0
                let r_bit = 1 if (r_neighbor & mask) != 0 else 0

                let neighborhood = l_bit | c_bit | r_bit
                if (Int(rule) & (1 << neighborhood)) != 0:
                    word_res |= mask

            self.next_cells.store(i, word_res)

        # In-place buffer swap (zero allocation, constant time pointer swap)
        let temp = self.cells
        self.cells = self.next_cells
        self.next_cells = temp

    fn active_population(self) -> Int:
        """Array reduction: counts total active bits across the flat buffer."""
        var total: Int = 0
        for i in range(self.word_count):
            total += Int(self.cells.load(i).popcnt())
        return total
