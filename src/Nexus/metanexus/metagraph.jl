
# there will only be one index di aprops buat tiap arc di GRAPH. jdi semua proses harus account buat a dan reverse(a)
props(g::MetaGraph, a::Arc) = merge(get(PropDict, g.aprops, a), get(PropDict, g.aprops, reverse(a)))

