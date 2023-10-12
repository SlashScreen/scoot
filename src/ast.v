module main

struct Ast {
pub mut:
	tree []Node
}

type Node = VarDef | BinOp | UnOp | Block | Assignment | IdentDef | IntDef | FloatDef | Branch | Ret | TypeDef

struct IdentDef {
pub:
	name string
}

struct IntDef {
pub:
	number usize
}

struct FloatDef {
pub:
	number f32
}

struct StringDef {
pub:
	str string
}

struct VarDef {
pub:
	name &Node
	type_def &Node
	declaration &Node
	is_const bool
}

struct BinOp {
pub:
	lhs &Node
	rhs &Node
	op BinOperation
}

struct Assignment {
	BinOp
}

struct UnOp {
pub:
	rhs &Node
	op UnOperation
}

struct Block {
pub mut:
	exprs []&Node
}

struct Branch {
pub mut:
	conditions []ConditionBlock
	else_block &Node
}

fn (b Branch) get_else() ?&Node {
	return if unsafe { b.else_block == nil } {
		?&Node(none)
	} else {
		?&Node(b.else_block)
	}
}

struct ConditionBlock {
pub:
	condition &Node
	block &Node
}

struct Ret {
pub mut:
	value &Node
}

fn (r Ret) get_val() ?&Node {
	return if unsafe { r.value == nil } {
		?&Node(none)
	} else {
		?&Node(r.value)
	}
}

struct FnDef {
pub mut:
	name &Node
	params ?[]&Node
	ret_type ?&Node
	block &Node
}

struct FnCall {
pub mut:
	name &Node
	params ?[]&Node
}

enum BinOperation {
	add subtract multiply divide mod // Arithmetic
	and_op or_op eq neq leq geq // Comparison
	bit_sft_l bit_sft_r bit_or bit_and bit_xor bit_not // Bitwise
	assign plus_as min_as div_as mul_as mod_as // Assignment
}

enum UnOperation {
	not
	negate
	pointer
}
