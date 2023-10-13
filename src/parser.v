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

fn (mut p Parser) skip_eol() ! {
	for p.current()!.tag == .eol {
		p.consume_token(.eol)!
	}
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
		.plus, .minus, .slash, .asterisk, .percent, .caret, .pipe, .ampersand, .or_or, .and_and, .bang, .eqeq, .neq, .leq, .geq { true }
		else { false }
	}
}

fn is_symbol_assignment(symbol Symbol) bool {
	return match symbol {
		.eq, .ast_eq, .sla_eq, .plu_eq, .min_eq, .and_eq, .or_eq, .xor_eq, .mod_eq { true }
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

fn (mut p Parser) consume_ident() !usize {
	t := p.current()!

	p.consume_token(.ident)!

	n := IdentDef{name: t.context}
	return p.ast.push_node(n)
}

fn (mut p Parser) consume_number() !usize {
	t := p.current()!

	p.consume_token(.num)!

	n := IntDef{number: t.context.u16()}
	return p.ast.push_node(n)
}

fn precedence(tag Symbol) int {
	return match tag {
		.eqeq, .geq, .leq, .neq { 0 }
		.and_and, .or_or, .percent { 10 }
		.plus, .minus { 20 }
		.caret, .pipe, .ampersand, .bang, .shl, .shr, .slash, .asterisk { 50 }
		else { 0 }
	}
}

fn tag_to_op(tag Symbol) ?BinOperation {
	return match tag {
		.plus { ?BinOperation(.add) }
		.minus { ?BinOperation(.subtract) }
		.asterisk { ?BinOperation(.multiply) }
		.slash { ?BinOperation(.divide) }
		.percent { ?BinOperation(.mod) }
		.and_and { ?BinOperation(.and_op) }
		.or_or { ?BinOperation(.or_op) }
		.eqeq { ?BinOperation(.eq) }
		.neq { ?BinOperation(.neq) }
		.leq { ?BinOperation(.leq) }
		.geq { ?BinOperation(.geq) }
		.shl { ?BinOperation(.bit_sft_l) }
		.shr { ?BinOperation(.bit_sft_r) }
		.pipe { ?BinOperation(.bit_or) }
		.ampersand { ?BinOperation(.bit_and) }
		.caret { ?BinOperation(.bit_xor) }
		.bang { ?BinOperation(.bit_not) }
		.eq { ?BinOperation(.assign) }
		.plu_eq { ?BinOperation(.plus_as) }
		.min_eq { ?BinOperation(.min_as) }
		.sla_eq { ?BinOperation(.div_as) }
		.ast_eq { ?BinOperation(.mul_as) }
		.mod_eq { ?BinOperation(.mod_as) }
		.and_eq { ?BinOperation(.and_as) }
		.or_eq { ?BinOperation(.or_as) }
		.xor_eq { ?BinOperation(.xor_as) }
		else { ?BinOperation(none) }
	}
}

fn (mut p Parser) consume_args_list() ![]uint {
	output := []uint{}
	for p.current()!.tag != .r_paren {
		p.skip_eol()!
		output << p.consume_expression()!
		if p.current()!.tag != .r_paren() {
			p.consume_token(.comma)! // comma delimited list
		}
	}
	return output
}

fn (mut p Parser) consume_params_list() ![]uint {
	output := []uint{}
	for p.current()!.tag != .r_paren {
		p.skip_eol()!
		output << p.ast.push_node(ParamInfo{
			name: p.consume_ident()!
			type_def: p.consume_ident()!
		})
		if p.current()!.tag != .r_paren() {
			p.consume_token(.comma)! // comma delimited list
		}
	}
	return output
}

// * EXPRESSIONS

fn (mut p Parser) consume_expression() !usize { // TODO: Rework
	match p.current()!.tag {
		.ident {
			l := p.lookahead(0)!
			if is_symbol_operator(l.tag) { return p.consume_algebraic(p.consume_atom()!, 0)! }
			else if l.tag == .eol { return p.consume_ident() }
			else {
				return error("Unexpected token.")
			}
		}
		.num {
			l := p.lookahead(0)!
			if l.tag == .eol { return p.consume_number() } // TODO: Floats
			else { return error("Unexpected token.") }
		}
		else { return error("Unexpected token.") }
	}
}

fn (mut p Parser) consume_atom() !usize {
	return match p.current()!.tag {
		.ident { p.consume_ident()! }
		.num { p.consume_number()! }
		else { error("Expected ident or number literal") }
	}
}

fn (mut p Parser) consume_algebraic(lhs usize, min_prec int) !usize {
	mut l_tok := p.current()!
	mut l_rhs := usize(0)
	mut la_tok := p.current()!

	for precedence(l_tok.tag) >= min_prec {
		op := la_tok
		p.shift()
		mut rhs := p.consume_atom()!
		la_tok = p.current()!

		for precedence(l_tok.tag) >= precedence(op.tag) {
			rhs = p.consume_algebraic(
				rhs, 
				precedence(op.tag) + if precedence(l_tok.tag) > precedence(op.tag) { 1 } else { 0 }
			)!
			la_tok = p.lookahead(0)!
		}

		l_rhs = rhs
	}

	return p.ast.push_node(BinOp{lhs:lhs, rhs:l_rhs, op:tag_to_op(la_tok.tag) or { return error("Unknown operator") }})
}

fn (mut p Parser) consume_func_call() !usize {
	name := p.consume_ident()!
	p.consume_ident(.l_paren)!
	args := p.consume_args_list()!
	p.consume_token(.r_paren)!
	return p.ast.push_node(FnCall{
		name: name
		params: if args.len > 0 { ?[]usize(args) } else { ?[]usize(none) }
	})
}

// * STATEMENTS

fn (mut p Parser) consume_statement() !usize {
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

fn (mut p Parser) consume_block() !usize {
	p.consume_token(.l_bracket)!
	p.consume_token(.eol)!
	mut exprs := []usize{}
	for p.current()!.tag != .r_bracket {
		if p.current()!.tag == .eol { continue }
		exprs << p.consume_expression()!
	}

	n := Block{exprs: exprs}
	return p.ast.push_node(n)
}

fn (mut p Parser) consume_assignment() !usize {
	return error("Todo")
}

fn (mut p Parser) consume_branch() !usize {
	p.consume_token(.key_branch)!
	mut conditions := []ConditionBlock{}
	mut e_block := ?usize(none)

	if p.current()!.tag != .l_bracket {
		e := p.consume_expression()!
		b := p.consume_block()!
		conditions << ConditionBlock{condition:e, block:b}
	} else {
		p.consume_token(.l_bracket)!
		p.skip_eol()!
		for p.current()!.tag != .r_bracket {
			match p.current()!.tag {
				.ident {
					if p.current()!.context == "_" {
						p.shift()
						b := p.consume_block()!
						e_block = ?usize(b)
					} else {
						e := p.consume_expression()!
						b := p.consume_block()!
						conditions << ConditionBlock{condition:e, block:b}
					}
				}
				.eol { continue }
				else {
					e := p.consume_expression()!
					b := p.consume_block()!
					conditions << ConditionBlock{condition:e, block:b}
				}
			}
		}
	}

	p.consume_token(.r_bracket)!
	p.skip_eol()!

	n := Branch{conditions:conditions, else_block:unsafe {e_block or {nil}}}
	return p.ast.push_node(n)
}

fn (mut p Parser) consume_return() !usize {
	p.consume_token(.key_return)!
	e := if p.current()!.tag != .eol {
		?usize(p.consume_expression()!)
	} else { ?usize(none) }

	n := Ret{ value: unsafe{ e or { nil } } }
	return p.ast.push_node(n)
}

// * TOPLEVEL

fn (mut p Parser) consume_toplevel() !usize {
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

fn (mut p Parser) consume_fn() !usize {
	name := !p.consume_ident()!
	p.consume_token(.double_colon)!
	p.consume_token(.key_fn)!
	p.consume_token(.l_paren)!
	params := p.consume_params_list()!
	p.consume_token(.r_paren)!
	ret_type := if p.current()!.tag == .ident {
		?usize(p.consume_ident()!)
	} else if p.current()!.tag != .l_bracket {
		return error("Expected type name as return type")
	} else {
		?usize(none)
	}
	block := p.consume_block()!

	return p.ast.push_node(FnDef{
		name: name
		params: if params.len > 0 { ?[]usize(params) } else { ?[]usize(none) }
		ret_type: ret_type
		block: block
	})
}

fn (mut p Parser) consume_type() !usize {
	return error("Todo")
}

fn (mut p Parser) consume_definition() !usize {
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

fn (mut p Parser) consume_var(constant bool) !usize {
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
	return p.ast.push_node(n)
}
