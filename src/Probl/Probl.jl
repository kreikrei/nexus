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

permintaan = readdata("/data/master-permintaan.csv")
demandlist = demands(permintaan)
demandscenarios = generatedemands(demandlist, 200, 1000)

# input: demandlist, basedigraph
expandedgraph = expand(basedigraph, demandlist)

using JuMP
m = Model()

@variable(m, 0 <= flow[a=arcs(expandedgraph)], Int)
@variable(m, 0 <= trip[a=arcs(expandedgraph)], Int)

@constraint(m, bal[n=nodes(expandedgraph)],
    sum(flow[a] for a in arcs(expandedgraph, :, [n])) -
    sum(flow[a] for a in arcs(expandedgraph, [n], :)) == demandlist[n]
) # flow balance

@constraint(m, cap[a=arcs(expandedgraph)],
    flow[a] <= expandedgraph[a][:Q] * trip[a]
) # arc capacity

@constraint(m, lim[a=arcs(expandedgraph)],
    trip[a] <= expandedgraph[a][:limit]
)

@objective(m, Min, sum(
        expandedgraph[a][:cpeti] * flow[a] + 
        expandedgraph[a][:cjarak] * expandedgraph[a][:dist] * trip[a]
        for a in arcs(expandedgraph)
    ) #+ sum(z)
)

using Gurobi
set_optimizer(m, Gurobi.Optimizer)

set_optimizer_attributes(m, "Threads" => 8)
set_optimizer_attributes(m, "Presolve" => 2)
set_optimizer_attributes(m, "Cuts" => 2)
set_optimizer_attributes(m, "MIPFocus" => 3)

optimize!(m)

objective_value(m)
for a in arcs(expandedgraph)
    set_prop!(expandedgraph, a, :flow, value(flow[a]))
    set_prop!(expandedgraph, a, :trip, value(trip[a]))
end

transport_result = Iterators.filter(p -> expandedgraph[p][:flow] > 0 && expandedgraph[p][:type] == :transport, arcs(expandedgraph)) |> collect

for a in transport_result
    println("$a flow = $(value(flow[a])) | trip = $(value(trip[a]))")
end


# 1. generate all nodes
# 2. generate all arcs
#    a. holdover arcs
#    b. transportation arcs
# 3. ensure zero sum demand

# TODO #3 function to build deterministic model from expanded network
# TODO #16 function to build stochastic model from expanded network