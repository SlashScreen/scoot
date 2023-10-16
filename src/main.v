module main

fn main() {
	mut l := Lexer.new("
main :: fn (a:int, b:int) int {
	c : int = 6
	return a + b + c
}
	")
	mut p := Parser.new(l.lex()!)
	println(p.consume_toplevel()!)
}
