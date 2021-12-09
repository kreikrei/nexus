module Nexus

using SimpleTraits
using Lazy

import Base:
    show, eltype, Tuple, iterate, length, reverse

include("interface.jl") # general stuff
include("arc.jl") # core graph
include("digraph.jl")
include("graph.jl")
include("arciter.jl")

export
    Graph, Digraph, Arc, ArcIter, add_arc!, rem_arc!, nn, na, nodes, arcs, fadj, badj

end