# defines problem structures and its conversion process from raw data
using CSV
using DataFrames
using Distances
using Turing

include("$(pwd())/src/Nexus/Nexus.jl")
include("io.jl")
include("forwarding.jl")
include("basenet.jl")
include("expandednet.jl")

khazanah = readdata("/data/khazanah-master.csv")
trayek = readdata("/data/trayek-usulan-essence.csv")
moda = readdata("/data/moda-hasil-estim copy.csv")

basegraph = baseGraph(khazanah, trayek, moda)
basedigraph = baseDigraph(basegraph)

permintaan = readdata("/data/permintaan-recreated.csv")

demandlist = demands(permintaan)
demandscenarios = generatedemands(demandlist, 200, 1000)

# input: demandlist, basedigraph
T_min,t_min_idx = findmin([lp.per for lp in keys(demandlist)])
T_max,t_max_idx = findmax([lp.per for lp in keys(demandlist)])

# 1. generate all nodes
# 2. generate all arcs
#    a. holdover arcs
#    b. transportation arcs
# 3. ensure zero sum demand

# tes lagi dulu deh

# TODO #2 function to transform base network into expanded network
# TODO #3 function to build deterministic model from expanded network
# TODO #4 model to generate demand sample
# TODO #5 function to build stochastic model from expanded network