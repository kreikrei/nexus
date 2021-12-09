workdir = pwd()

refpath = "$workdir/src/Nexus"
push!(LOAD_PATH, refpath)

using Revise
import Nexus:
    Graph, Digraph, Arc, ArcIter, add_arc!, rem_arc!, nn, na, nodes, arcs, fadj, badj

