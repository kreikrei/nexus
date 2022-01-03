# defines problem structures and its conversion process from raw data
using CSV
using DataFrames
using Distances
using JuMP
using Gurobi
using StochasticPrograms

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

# tesdemands = generatedemand(demandlist, 100, 10)
# tesdemand = rand(tesdemands)

deter = deterministicmodel(expandedgraph, demandlist)
#= deter = deterministicmodel(expandedgraph, tesdemand)

# deter_f = deterministicmodel_f(expandedgraph, tesdemand)

t_min = findmin([k.per for k in keys(tesdemand)]) |> first
t_max = findmax([k.per for k in keys(tesdemand)]) |> first

@constraint(deter, cut[t = t_min:t_max], 
    sum((deter[:trip][a] - deter[:surp][a]) * expandedgraph[a][:Q] 
        for a in arcs(expandedgraph, :, filter(p -> p.per == t, nodes(expandedgraph) |> collect))
    ) -
    sum((deter[:trip][a] - deter[:surp][a])* expandedgraph[a][:Q] 
        for a in arcs(expandedgraph, filter(p -> p.per == t, nodes(expandedgraph) |> collect), :)
    ) == sum(tesdemand[n] for n in filter(p -> p.per == t, nodes(expandedgraph) |> collect))
)

for t in t_min:t_max
    @constraint(deter, [a = union(
        arcs(expandedgraph, :, filter(p -> p.per == t, nodes(expandedgraph) |> collect)), arcs(expandedgraph, filter(p -> p.per == t, nodes(expandedgraph) |> collect), :)
        )
    ], (deter[:trip][a] - deter[:surp][a]) * expandedgraph[a][:Q] <= deter[:trip][a] * expandedgraph[a][:Q]
    )
end

locations = [d.loc for d in keys(tesdemand)] |> unique!

@constraint(deter, l_cut[l=locations],
    sum((deter[:trip][a] - deter[:surp][a]) * expandedgraph[a][:Q] 
    for a in arcs(expandedgraph, :, filter(p -> p.loc == l, nodes(expandedgraph) |> collect))
    ) -
    sum((deter[:trip][a] - deter[:surp][a])* expandedgraph[a][:Q] 
    for a in arcs(expandedgraph, filter(p -> p.loc == l, nodes(expandedgraph) |> collect), :)
    ) == sum(tesdemand[n] for n in filter(p -> p.loc == l, nodes(expandedgraph) |> collect))
)=#

set_optimizer(deter, Gurobi.Optimizer)
set_optimizer_attributes(deter, "Threads" => 8)
# set_optimizer_attributes(deter, "Presolve" => 2)
# set_optimizer_attributes(deter, "Cuts" => 2)
set_optimizer_attributes(deter, "MIPGap" => 0.05)
optimize!(deter)

compute_conflict!(deter)

# TODO #3 function to build deterministic model from expanded network
# TODO #16 function to build stochastic model from expanded network
# TODO #17 create a possible demand from rekap remise close enough to real demand

