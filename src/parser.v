module main

struct Parser {
	input []Token
mut:
	pos usize
	ast Ast
}

fn (mut p Parser) shift() {
	p.pos += 1
}

fn (p Parser) lookahead(index usize) !Token {
	if p.pos >= p.input.len {
		return error("Reached EOF unexpectedly.")
	} else {
		return p.input[p.pos + (index + 1)]
	}
}

fn (p Parser) current() !Token {
	if p.pos >= p.input.len {
		return error("Reached EOF unexpectedly.")
	} else {
		return p.input[p.pos]
	}
}

fn (mut p Parser) parse() !Ast {
	for p.pos < input.len {
		t := p.current()!
		match t.tag {
			.ident {
				l := p.lookahead()!
				match l.tag {
					.colon, .double_colon {}
				}
			}
			else { return error("Unexpected token.") }
		}

		p.shift()
	} 

	return Ast
}

fn (mut p Parser) consume_token(tag Symbol) ! {
	t := p.current()!
	if t.tag != tag {
		return error("${t.format_start()}: Expected Ident, got ${t.tag}.")
	}
	p.shift()
}

fn (mut p Parser) consume_ident() !&Node {
	t := p.current()!

	p.consume_token(.ident)!

	n := IdentDef{name: t.context}
	p.ast.tree << n
	return &n
}

fn (mut p Parser) consume_definition() !&Node {
	return match p.lookahead(0)!.tag {
		.colon { p.consume_var(false)! }
		.double_colon {
			match p.lookahead(1)!.tag {
				.key_fn { p.consume_fn()! }
				else { p.consume_var(true)! }
			}
		}
		else { return error("Expected variable or function definition.") }
	}
}

fn (mut p Parser) consume_var(constant bool) !&Node {
	name := p.consume_ident()!
	match p.current()!.tag {
		.colon { p.consume_token(.colon)! }
		.double_colon { p.consume_token(.double_colon)! }
		else { }
	}
	type_name := p.consume_ident()!
	p.consume_token(.eq)!
	n := VarDef { 
		name: name
		type_def: type_name
		declaration: p.consume_expression()!
		constant: constant
	}
	p.ast.tree << n
	return &n
}

fn (mut p Parser) consume_fn() !&Node {
	return error("Todo")
}

fn (mut p Parser) consume_expression() !&Node {
	
}

fn (mut p Parser) consume_statement() !&Node {
	t := p.current()!
	return match t.tag {
		.ident {
			l := p.lookahead()!
			match l.tag {
				.colon, .double_colon { p.consume_definition()! }
				else { error ("Unexpected token.") }
			}
		}
		else { error("Unexpected token.") }
	}
}

// * AST

struct Ast {
pub mut:
	tree []&Node
}

type Node = VarDef | ConstDef | Expression

type Expression = BinOp | UnOp | Literal | Block | Assignment

type Literal = IdentDef | IntDef | FloatDef

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
	lhs &Expression
	rhs &Expression
	op BinOperation
}

struct Assignment {
	BinOp
}

struct UnOp {
pub:
	rhs &Expression
	op UnOperation
}

struct Block {
pub mut:
	eprs []&Expression
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
