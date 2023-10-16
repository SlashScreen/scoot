module main 

fn test_parser() ! {
	l := Lexer.new("
main :: fn (a:int, b:int) int {
	c : int = 6
	return a + b + c
}
	")
	p := Parser.new(.lex()!)
	print(p)
}
