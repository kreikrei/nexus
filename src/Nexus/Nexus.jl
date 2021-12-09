using SimpleTraits
using Lazy

import Base:
    show, eltype, Tuple, iterate, length, reverse

include("interface.jl") # general stuff

include("./simplenexus/arc.jl") # core graph
include("./simplenexus/digraph.jl")
include("./simplenexus/graph.jl")
include("./simplenexus/arciter.jl")

include("./metanexus/metagraph.jl") # attribs
include("./metanexus/metadigraph.jl")

export
    Graph, Digraph, Arc, ArcIter, add_arc!, rem_arc!, nn, na, nodes, arcs