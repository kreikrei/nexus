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
expandedgraph = expand(basedigraph, demandlist)

using JuMP
m = Model()

@variable(m, 0 <= flow[a=arcs(expandedgraph)])
@variable(m, 0 <= trip[a=arcs(expandedgraph)], Int)
# @variable(m, z[a=arcs(basedigraph)], Bin)

@constraint(m, bal[n=nodes(expandedgraph)],
    sum(flow[a] for a in arcs(expandedgraph, :, [n])) -
    sum(flow[a] for a in arcs(expandedgraph, [n], :)) == demandlist[n]
) # flow balance

@constraint(m, cap[a=arcs(expandedgraph)],
    flow[a] <= expandedgraph[a][:Q] * trip[a]
) # arc capacity
#= @constraint(m, lim[a=Nexus.filter_arcs(expandedgraph, :type, :transport)],
    trip[a] <= expandedgraph[a][:limit] * z[Arc(src(a).loc,tgt(a).loc,key(a))]
) =#

#= @constraint(m, rev[a=arcs(basedigraph)],
    z[a] == z[reverse(a)]
)=#
@objective(m, Min, sum(
        expandedgraph[a][:cpeti] * flow[a] + 
        expandedgraph[a][:cjarak] * expandedgraph[a][:dist] * trip[a]
        for a in arcs(expandedgraph)
    ) #+ sum(z)
)

using Gurobi
set_optimizer(m, Gurobi.Optimizer)

optimize!(m)

compute_conflict!(m)
if MOI.get(m, MOI.ConflictStatus()) != MOI.CONFLICT_FOUND
    error("No conflict could be found for an infeasible model.")
end

for n in nodes(expandedgraph)
    if MOI.get(m, MOI.ConstraintConflictStatus(), bal[n]) == MOI.IN_CONFLICT
        println("$n : IN_CONFLICT")
    end
end



arcs(expandedgraph, :, [locper(vault("Jakarta"),12)]) |> collect
arcs(expandedgraph, [locper(vault("Jakarta"),12)], :) |> collect

arcs(expandedgraph, :, [locper(vault("SINK"),14)]) |> collect

bal[locper(vault("Denpasar"),12)]

new_model, reference_map = copy_conflict(m)



Gurobi.compute_conflict(backend(m))
MOI.get(model, Gurobi.ConstraintConflictStatus(), c)
MOI.get(model, Gurobi.ConstraintConflictStatus(), LowerBoundRef(x))

for a in arcs(expandedgraph)
    if !Nexus.has_arc(expandedgraph, reverse(a))
        println("arc $a doesn't have reverse")
    end
end
@objective(FCNF, Min, sum(G[a,:f] * y[a] + G[a,:g] * x[a] for a in arcs(G)))

# 1. generate all nodes
# 2. generate all arcs
#    a. holdover arcs
#    b. transportation arcs
# 3. ensure zero sum demand

# TODO #3 function to build deterministic model from expanded network
# TODO #16 function to build stochastic model from expanded network