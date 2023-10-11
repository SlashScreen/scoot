module main

struct Signature {
pub:
    s_type string
}

struct SymbolTable {
mut:
    scopes []map[string]Signature
}

fn (mut st SymbolTable) enter_scope() {
    st.scopes << map[string]Signature{}
}

fn (mut st SymbolTable) exit_scope() {
    st.scopes.delete_last()
}

fn (st SymbolTable) find_symbol(name string) ?Signature {
    for sc in st.scopes {
        if name in sc {
            return sc[name]
        }
    }
    return none
}

fn (st SymbolTable) check_symbol(name string) bool {
    return if _s := st.find_symbol(name) {
        true
    } else {
        false
    }
}

fn (mut st SymbolTable) add_symbol(name string, def Signature) {
    st.scopes.last()[name] = def
}
