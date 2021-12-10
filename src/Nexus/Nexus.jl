module Nexus

using SimpleTraits
using Lazy

import Base:
    show, eltype, Tuple, iterate, length, reverse

include("interface.jl")

include("./simplenexus/arc.jl")
include("./simplenexus/digraph.jl")
include("./simplenexus/graph.jl")
include("./simplenexus/arciter.jl")

export
    Graph, Digraph, Arc, ArcIter, 
    add_arc!, rem_arc!, add_node!, rem_node!, 
    nn, na, nodes, arcs, fadj, badj, has_arc, has_node, 
    src, tgt, key

end