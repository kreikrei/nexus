

@forward MetaDigraph.core badj

props(g::MetaDigraph, a::Arc) = get(PropDict, g.aprops, a)