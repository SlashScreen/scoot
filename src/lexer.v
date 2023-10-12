module main

struct Lexer {
	input string
mut:
	pos u32
	output []Symbol
}

fn Lexer.new(input string) Lexer {
	return Lexer{input:input + " " }
}

fn (mut l Lexer) lex() ![]Token {
	mut output := []Token{}
	for l.pos < l.input.len {
		output << l.consume()!
	}
	return output
}

fn (mut l Lexer) shift() {
	l.pos += 1
}

fn  (mut l Lexer) consume() !Token {
	mut token := Token{start: l.pos, tag: .eof}
	mut state := State.start

	for l.pos < l.input.len {
		c := l.input.runes()[l.pos]
		lookbehind := if l.pos == 0 { 
			?rune(none)
		} else { 
			?rune(l.input.runes()[l.pos - 1]) 
		}

		match state {
			.start {
				match c {
					` `, `\t` { 
						l.shift() 
						token.start += 1
					}
					`a`...`z`, `A`...`Z`, `_` { 
						state = .ident
						l.shift() 
					}
					`0`...`9` {
						state = .num
						l.shift()
					}
					`!`, `=`, `|`, `&`, `+`, `-`, `*`, `/`, `^`, `:`, `<`, `>`, `%` {
						r := match c {
							`!` { ?State(State.bang) }
							`=` { ?State(State.eq) }
							`|` { ?State(State.pipe) }
							`&` { ?State(State.ampersand) }
							`+` { ?State(State.plus) }
							`-` { ?State(State.minus) }
							`*` { ?State(State.asterisk) }
							`/` { ?State(State.slash) }
							`^` { ?State(State.caret) }
							`:` { ?State(State.colon) }
							`<` { ?State(State.l_ang) }
							`>` { ?State(State.r_ang) }
							`%` { ?State(State.mod) }
							else { none }
						}
						state = r or { return error('Parsing bug - symbols.') }
						l.shift()
					}
					`{`, `}`, `(`, `)`, `[`, `]`, `.`, `,`, `\n`, `;` {
						r := match c {
							`{` { ?Symbol(Symbol.l_bracket) }
							`}` { ?Symbol(Symbol.r_bracket) }
							`(` { ?Symbol(Symbol.l_paren) }
							`)`	{ ?Symbol(Symbol.r_paren) }
							`[` { ?Symbol(Symbol.l_brace) }
							`]`	{ ?Symbol(Symbol.r_brace) }
							`.` { ?Symbol(Symbol.dot) }
							`,` { ?Symbol(Symbol.comma) }
							`\n`, `;` { ?Symbol(Symbol.eol) }
							else { none }
						}

						token.tag = r or { return error('Parsing bug - enclosing.') }
						l.shift()
						break
					}
					`#` { 
						state = .comment
						l.shift()
					}
					else { return error('Unexpected character ${c} at ${l.pos}') }
				}
			}
			.ident {
				match c {
					`a`...`z`, `A`...`Z`, `0`...`9`, `_`, `!`, `?` { l.shift() }
					else {
						token.tag = match l.input[token.start..l.pos] {
							"branch" { .key_branch }
							"loop" { .key_loop }
							"break" { .key_break }
							"type" { .key_type }
							"fn" { .key_fn }
							"return" { .key_return }
							"interface" { .key_interface }
							"else" { .key_else }
							else { .ident }
						}
						break
					}
				}
			}
			.num {
				match c {
					`0`...`9` { l.shift() }
					else {
						if lb := lookbehind {
							if lb == `0` {
								match c {
									// This is for 0x, 0b
									`x` {
										token.tag = .hex_mode
										l.shift()
									}
									`b` {
										token.tag = .binary_mode
										l.shift()
									}
									else { token.tag = .num }
								}
								break
							}
						}
						token.tag = .num
						break
					}
				}
			}
			.l_ang, .r_ang {
				match c {
					`=` {
						r := match state {
							.l_ang { ?Symbol( Symbol.leq ) }
							.r_ang { ?Symbol( Symbol.geq ) }
							else { none }
						}
						token.tag = r or { return error('Parsing bug - <>.') } 
						l.shift()
						break 
					}
					`<`, `>` {
						r := match true {
							state == .l_ang && c == `<` { ?Symbol( Symbol.shl ) }
							state == .r_ang && c == `>` { ?Symbol( Symbol.shr ) }
							else { none }
						}
						token.tag = r or { return error('Parsing bug - <<>>.') } 
						l.shift()
						break 
					}
					else {
						r := match state {
							.l_ang { ?Symbol( Symbol.l_angle ) }
							.r_ang { ?Symbol( Symbol.r_angle ) }
							else { none }
						}
						token.tag = r or { return error('Parsing bug - <> normal.') }
						break
					}
				}
			}
			.bang, .eq, .asterisk, .slash, .plus, .minus, .mod, .caret {
				match c {
					`=` { 
						r := match state {
							.bang { ?Symbol( Symbol.neq ) }
							.eq { ?Symbol( Symbol.eqeq ) }
							.asterisk { ?Symbol( Symbol.ast_eq ) }
							.slash { ?Symbol( Symbol.sla_eq ) }
							.plus { ?Symbol( Symbol.plu_eq ) }
							.minus { ?Symbol( Symbol.min_eq ) }
							.mod { ?Symbol( Symbol.mod_eq ) }
							.caret { ?Symbol( Symbol.xor_eq ) }
							else { none }
						}
						token.tag = r or { return error('Parsing bug - eq.') } 
						l.shift()
						break 
					}
					else {  
						r := match state {
							.bang { ?Symbol( Symbol.bang ) }
							.eq { ?Symbol( Symbol.eq ) }
							.asterisk { ?Symbol( Symbol.asterisk ) }
							.slash { ?Symbol( Symbol.slash ) }
							.plus { ?Symbol( Symbol.plus ) }
							.minus { ?Symbol( Symbol.minus ) }
							.mod { ?Symbol( Symbol.percent ) }
							.caret { ?Symbol( Symbol.caret ) }
							else { none }
						}
						token.tag = r or { return error('Parsing bug - eq normal.') }
						break
					}
				}
			}
			.colon {
				match c {
					`:` {
						token.tag = .double_colon
						l.shift()
						break
					}
					else {
						token.tag = .colon
						l.shift()
						break
					}
				}
			}
			.pipe, .ampersand {
				match c {
					`|`, `&` {
						r := match c {
							`|` { ?Symbol(Symbol.or_or) }
							`&` { ?Symbol(Symbol.and_and) }
							else { none }
						}
						token.tag = r or { return error('Parsing bug - and and.') }
						l.shift()
						break
					}
					`=` {
						r := match state {
							.pipe { ?Symbol(Symbol.or_eq) }
							.ampersand { ?Symbol(Symbol.and_eq) }
							else { none }
						}
						token.tag = r or { return error('Parsing bug - and eq.') }
						l.shift()
						break
					}
					else {
						r := match state {
							.pipe { ?Symbol(Symbol.pipe) }
							.ampersand { ?Symbol(Symbol.ampersand) }
							else { none }
						}
						token.tag = r or { return error('Parsing bug - and eq.') }
						l.shift()
						break
					}
				}
			}
			.comment {
				match c {
					`\n` {
						token.tag = .eol
						l.shift()
						break
					}
					else {
						l.shift()
						token.start += 1
					}
				}
			}
		}
	}

	token.end = l.pos
	token.context = l.input[token.start..token.end]
	return token
}

enum Symbol as u8 {
	ident num // Atoms
	plus minus slash asterisk percent caret pipe ampersand or_or and_and bang shl shr // Binary stuff, no equals
	eq eqeq neq ast_eq sla_eq plu_eq min_eq and_eq or_eq xor_eq mod_eq leq geq // Equals
	eol colon double_colon dot comma l_bracket r_bracket l_paren r_paren l_angle r_angle r_brace l_brace // Particles
	key_branch key_loop key_type key_interface key_fn key_return key_break key_else // Keywords
	hex_mode binary_mode // 0x, 0b
	eof
}

enum State {
	start comment // State
	ident num // Atoms
	bang eq asterisk slash plus minus mod pipe ampersand caret // Operators
	colon l_ang r_ang // Particles
}

struct Token {
pub mut:
	start u32
	end u32
	context string
	tag Symbol
}

fn (t Token) format_start() string {
	return ""
}
