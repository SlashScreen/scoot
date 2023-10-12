module main

const (
	tags = [
		Symbol.ident, Symbol.num, Symbol.num, Symbol.eol
		Symbol.key_fn, Symbol.key_branch, Symbol.key_loop, Symbol.key_break, Symbol.key_return, Symbol.eol
		Symbol.l_paren, Symbol.r_paren, Symbol.l_bracket, Symbol.r_bracket, Symbol.l_brace, Symbol.r_brace, Symbol.dot, Symbol.comma, Symbol.eol, Symbol.colon, Symbol.double_colon Symbol.eol
		Symbol.plus, Symbol.minus, Symbol.slash, Symbol.asterisk, Symbol.percent, Symbol.caret, Symbol.ampersand, Symbol.pipe, Symbol.l_angle, Symbol.r_angle, Symbol.bang, Symbol.shl, Symbol.shr, Symbol.eol
		Symbol.plu_eq, Symbol.min_eq, Symbol.sla_eq, Symbol.ast_eq, Symbol.xor_eq, Symbol.and_eq, Symbol.or_eq, Symbol.leq, Symbol.geq, Symbol.eqeq, Symbol.neq, Symbol.eol
		Symbol.and_and, Symbol.or_or, Symbol.eol
		Symbol.hex_mode, Symbol.binary_mode, Symbol.eol
		Symbol.eof
	]
)

fn test_lexer() ! {
	mut l := Lexer.new(
"foo 10 09
fn branch loop break return # comment
() {} [] . , ; : ::
+ - / * % ^ & | < > ! << >>
+= -= /= *= ^= &= |= <= >= == !=
&& ||
0x 0b
")
	r := l.lex()!

	for i, t in r {
		assert t.tag == tags[i], "Assertion failed. Got ${t.context} of type ${t.tag}"
	}
}
