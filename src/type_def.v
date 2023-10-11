module main

struct TypeDef {
pub mut:
    interfaces []string
    members    map[string]Member
	is_interface bool
}

type Member = Field | Method

struct Field {
pub:
    sig Signature
}

struct Method {
pub:
    params   []Signature
    ret_type Signature
}
