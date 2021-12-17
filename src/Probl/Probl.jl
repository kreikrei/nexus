# defines problem structures and its conversion process from raw data
using CSV
using DataFrames
using Distances
using JuMP
using Gurobi

include("$(pwd())/src/Nexus/Nexus.jl")
include("io.jl")
include("forwarding.jl")
include("basenet.jl")
include("expandednet.jl")
include("models.jl")

khazanah = readdata("/data/khazanah-master.csv")
trayek = readdata("/data/trayek-usulan-essence.csv")
moda = readdata("/data/moda-hasil-estim copy.csv")

basegraph = baseGraph(khazanah, trayek, moda)
basedigraph = baseDigraph(basegraph)

permintaan = readdata("/data/master-permintaan.csv")
demandlist = demands(permintaan)
demandscenarios = generatedemands(demandlist, 800, 1000)

expandedgraph = expand(basedigraph, demandscenarios[3])
deter = deterministicmodel(expandedgraph, demandscenarios[3])

set_optimizer(deter, Gurobi.Optimizer)
set_optimizer_attributes(deter, "Threads" => 8)
set_optimizer_attributes(deter, "Presolve" => 2)
set_optimizer_attributes(deter, "Cuts" => 2)
set_optimizer_attributes(deter, "MIPGap" => 0.04)

optimize!(deter)

# 1. generate all nodes
# 2. generate all arcs
#    a. holdover arcs
#    b. transportation arcs
# 3. ensure zero sum demand

# TODO #3 function to build deterministic model from expanded network
# TODO #16 function to build stochastic model from expanded network