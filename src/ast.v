module main

struct Ast {
pub mut:
	tree []Node
}

fn (mut ast Ast) push_node(n Node) usize {
	ast.tree << n
	return usize(ast.tree.len - 1)
}

type Node = 
	VarDef | 
	BinOp | 
	UnOp | 
	Block | 
	Assignment | 
	IdentDef | 
	IntDef | 
	FloatDef | 
	Branch | 
	Ret | 
	TypeDef | 
	ParamInfo

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
	name usize
	type_def usize
	declaration usize
	is_const bool
}

struct ParamInfo {
pub:
	name usize
	type_def usize
}

struct BinOp {
pub:
	lhs usize
	rhs usize
	op BinOperation
}

struct Assignment {
	BinOp
}

struct UnOp {
pub:
	rhs usize
	op UnOperation
}

struct Block {
pub mut:
	exprs []usize
}

struct Branch {
pub mut:
	conditions []ConditionBlock
	else_block ?usize
}

struct ConditionBlock {
pub:
	condition usize
	block usize
}

struct Ret {
pub mut:
	value ?usize
}

struct FnDef {
pub mut:
	name usize
	params ?[]usize
	ret_type ?usize
	block usize
}

struct FnCall {
pub mut:
	name usize
	params ?[]usize
}

enum BinOperation {
	add subtract multiply divide mod // Arithmetic
	and_op or_op eq neq leq geq // Comparison
	bit_sft_l bit_sft_r bit_or bit_and bit_xor bit_not // Bitwise
	assign plus_as min_as div_as mul_as mod_as or_as and_as xor_as // Assignment
}

enum UnOperation {
	not
	negate
	pousizeer
}
