from memory import Pointer

alias MAX_NODES = 16384
alias MAX_CLASSES = 16384
alias MAX_ARGS = 4

struct ENode:
    var op: UInt32
    var args: InlineArray[UInt32, MAX_ARGS]
    var arg_len: UInt8
    var eclass: UInt32

struct EClass:
    var representative: UInt32
    var next: UInt32 # Union-Find parent pointer

struct MojoEGraph:
    var enodes: Pointer[ENode]
    var enode_count: Int

    var eclasses: Pointer[EClass]
    var eclass_count: Int

    fn __init__(inout self):
        self.enodes = Pointer[ENode].alloc(MAX_NODES)
        self.eclasses = Pointer[EClass].alloc(MAX_CLASSES)
        self.enode_count = 0
        self.eclass_count = 0

    fn __del__(owned self):
        self.enodes.free()
        self.eclasses.free()

    @always_inline
    fn alloc_eclass(inout self, repr_node: UInt32) -> UInt32:
        let id = self.eclass_count
        self.eclass_count += 1

        # Self-referential initial union-find pointer
        var cls = EClass()
        cls.representative = repr_node
        cls.next = id.cast[UInt32]()
        self.eclasses.store(id, cls)
        return id.cast[UInt32]()

    @always_inline
    fn find(inout self, mut class_id: UInt32) -> UInt32:
        """Union-Find `find` with iterative path compression over flat memory."""
        var root = class_id
        while self.eclasses.load(root.cast[Int]()).next != root:
            root = self.eclasses.load(root.cast[Int]()).next

        # Compress path
        var curr = class_id
        while curr != root:
            let next_target = self.eclasses.load(curr.cast[Int]()).next
            var cls = self.eclasses.load(curr.cast[Int]())
            cls.next = root
            self.eclasses.store(curr.cast[Int](), cls)
            curr = next_target

        return root

    @always_inline
    fn union(inout self, class1: UInt32, class2: UInt32) -> Bool:
        """Merges two equivalence classes under congruence."""
        let root1 = self.find(class1)
        let root2 = self.find(class2)

        if root1 == root2:
            return False

        # Attach root2 under root1
        var cls2 = self.eclasses.load(root2.cast[Int]())
        cls2.next = root1
        self.eclasses.store(root2.cast[Int](), cls2)
        return True
