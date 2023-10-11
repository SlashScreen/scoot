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

fn is_symbol_operator(symbol Symbol) bool {
	return match symbol {
		.plus, .minus, .slash, .asterisk, .percent, .caret, .pipe, .ampersand, .or_or, .and_and, .bang { true }
		else { false }
	}
}

fn is_symbol_assignment(symbol Symbol) bool {
	return match symbol {
		.eq, .eqeq, .neq, .ast_eq, .sla_eq, .plu_eq, .min_eq, .and_eq, .or_eq, .xor_eq, .mod_eq, .leq, .geq { true }
		else { false }
	}
}

fn (mut p Parser) parse() !Ast {
	for p.pos < p.input.len {
		p.consume_toplevel()!
		p.shift()
	} 

	return p.ast
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
	p.ast.tree << &n
	return &n
}

fn (mut p Parser) consume_number() !&Node {
	t := p.current()!

	p.consume_token(.num)!

	n := IntDef{number: t.context.uint()}
	p.ast.tree << &n
	return &n
}

// * EXPRESSIONS

fn (mut p Parser) consume_expression() !&Node {
	match p.current()!.tag {
		.ident {
			l := p.lookahead(0)!
			if is_symbol_operator(l.tag) { return p.consume_algebraic() }
			else if l.tag == .eol { return p.consume_ident() }
			else {
				return error("Unexpected token.")
			}
		}
		.num {
			l := p.lookahead(0)!
			if l.tag == .eol { return p.consume_number() } // TODO: Floats
		}
		else { error("Unexpected token.") }
	}
}

fn (mut p Parser) consume_algebraic() !&Node {
	return error("Todo")
}

fn (mut p Parser) consume_func_call() !&Node {
	return error("Todo")
}

// * STATEMENTS

fn (mut p Parser) consume_statement() !&Node {
	t := p.current()!
	match t.tag {
		.ident {
			l := p.lookahead(0)!
			if is_symbol_assignment(l.tag) { return p.consume_assignment() }
			else {
				match l.tag {
					.colon, .double_colon { return p.consume_definition() }
					else { return error ("Unexpected token.") }
				}
			}
		}
		.key_branch { return p.consume_branch() }
		.key_type { return p.consume_return() }
		else { return error("Unexpected token.") }
	}
}

fn (mut p Parser) consume_block() !&Node {
	p.consume_token(.l_bracket)!
	p.consume_token(.eol)!
	mut exprs := []&Node{}
	for p.current()!.tag != .r_bracket {
		if p.current()!.tag == .eol { continue }
		exprs << p.consume_expression()!
	}

	n := Block{exprs: exprs}
	p.ast.tree << &n
	return &n
}

fn (mut p Parser) consume_assignment() !&Node {
	return error("Todo")
}

fn (mut p Parser) consume_branch() !&Node {
	p.consume_token(.key_branch)
	conditions := [](&Node, &Node){}

	if p.current()!.tag != .l_bracket {
		e := p.consume_expression()!
		b := p.consume_block()!
		conditions << (e, b)
	}

	p.consume_token(.l_bracket)!
	p.consume_token(.eol)!
}

fn (mut p Parser) consume_return() !&Node {
	p.consume_token(.key_return)!
	e := if p.current()!.tag != .eol {
		?Node(p.consume_expression()!)
	} else { ?Node(none) }

	n := Ret{ value: e }
	p.ast.tree << &n
	return &n
}

// * TOPLEVEL

fn (mut p Parser) consume_toplevel() !&Node {
	t := p.current()!
	match t.tag {
		.ident {
			match p.lookahead(0)!.tag {
				.double_colon { return p.consume_definition() }
				else { return error("Expected constant or function definition.") }
			}
		}
		.key_type, .key_interface { return p.consume_type() }
		else { return error("Unexpected symbols in top level.") }
	}
}

fn (mut p Parser) consume_fn() !&Node {
	return error("Todo")
}

fn (mut p Parser) consume_type() !&Node {
	return error("Todo")
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
		is_const: constant
	}
	p.ast.tree << &n
	return &n
}
