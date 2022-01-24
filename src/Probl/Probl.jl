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
trayek = readdata("/data/trayek-usulan-merged.csv")
moda = readdata("/data/moda-hasil-estim-copy.csv")

basegraph = baseGraph(khazanah, trayek, moda)
basedigraph = baseDigraph(basegraph)

permintaan = readdata("/data/master-permintaan.csv")
protodemandlist = demands(permintaan)

expandedgraph, demandlist = expand(basedigraph, protodemandlist)

tesdemands = generatedemand(demandlist, 100, 20)
tesdemand = rand(tesdemands)

deter = deterministicmodel(expandedgraph, tesdemand)

set_optimizer(deter, Gurobi.Optimizer)
set_optimizer_attributes(deter, "Threads" => 8)
set_optimizer_attributes(deter, "Presolve" => 2)
set_optimizer_attributes(deter, "Cuts" => 2)
set_optimizer_attributes(deter, "MIPFocus" => 1)
set_optimizer_attributes(deter, "MIPGap" => 0.05)
set_optimizer_attributes(deter, "OutputFlag" => 0)
optimize!(deter)

sol = MetaDigraph{locper}()
for a in deter[:flow].axes[1]
    if value(deter[:flow][a]) > 0
        add_arc!(sol, a)
        set_prop!(sol, a, :flow, value(deter[:flow][a]))
    end
end


# TODO #3 function to build deterministic model from expanded network
# TODO #16 function to build stochastic model from expanded network
# TODO #17 create a possible demand from rekap remise close enough to real demand