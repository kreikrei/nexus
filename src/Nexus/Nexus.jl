module Nexus

using SimpleTraits
using Lazy

import Base:
    show, eltype, Tuple, iterate, length, reverse

include("interface.jl")
include("arc.jl")
include("digraph.jl")
include("graph.jl")
include("arciter.jl")

export
    Graph, Digraph, Arc, ArcIter, 
    add_arc!, rem_arc!, add_node!, rem_node!, 
    nn, na, nodes, arcs, fadj, badj, 
    src, tgt, key

end