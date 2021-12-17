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
trayek = readdata("/data/trayek-usulan-essence.csv")
moda = readdata("/data/moda-hasil-estim copy.csv")

basegraph = baseGraph(khazanah, trayek, moda)
basedigraph = baseDigraph(basegraph)

permintaan = readdata("/data/master-permintaan.csv")
demandlist = demands(permintaan)

expandedgraph = expand(basedigraph, demandlist)
deter = deterministicmodel(expandedgraph, demandlist)

set_optimizer(deter, Gurobi.Optimizer)
set_optimizer_attributes(deter, "Threads" => 8)
set_optimizer_attributes(deter, "Presolve" => 2)
set_optimizer_attributes(deter, "Cuts" => 2)
set_optimizer_attributes(deter, "MIPGap" => 0.04)

optimize!(deter)

@stochastic_model simple_model begin
    @stage 1 begin
        @decision(simple_model, z[a in arcs(basedigraph)] >= 0)
        @objective(simple_model, Min, sum(z))
        @constraint(simple_model, rev[a in arcs(basedigraph)],
            z[a] == z[reverse(a)]
        )
    end
    @stage 2 begin
        @uncertain demand[n in nodes(expandedgraph)]
        @recourse(simple_model, flow[a in arcs(expandedgraph)] >= 0)
        @recourse(simple_model, trip[a in arcs(expandedgraph)] >= 0)
        @constraint(m, bal[n in nodes(expanded)],
            sum(flow[a] for a in arcs(expanded, :, [n])) -
            sum(flow[a] for a in arcs(expanded, [n], :)) == demand[n]
        )
        @constraint(m, cap[a in arcs(expanded)], flow[a] <= expanded[a][:Q] * trip[a])
        @constraint(m, lim[a in arcs(expanded)], trip[a] <= expanded[a][:limit])
        @objective(m, Min, 
            sum(
                expanded[a][:cpeti] * flow[a] + 
                expanded[a][:cjarak] * expanded[a][:dist] * trip[a]
                for a in arcs(expanded)
            )
        )
    end
end

Crops = [:wheat, :corn, :beets]
@stochastic_model farmer_model begin
    @stage 1 begin
        @parameters begin
            Crops = Crops
            Cost = Dict(:wheat=>150, :corn=>230, :beets=>260)
            Budget = 500
        end
        @decision(farmer_model, x[c in Crops] >= 0)
        @objective(farmer_model, Min, sum(Cost[c]*x[c] for c in Crops))
        @constraint(farmer_model, sum(x[c] for c in Crops) <= Budget)
    end
    @stage 2 begin
        @parameters begin
            Crops = Crops
            Required = Dict(:wheat=>200, :corn=>240, :beets=>0)
            PurchasePrice = Dict(:wheat=>238, :corn=>210)
            SellPrice = Dict(:wheat=>170, :corn=>150, :beets=>36, :extra_beets=>10)
        end
        @uncertain ξ[c in Crops]
        @recourse(farmer_model, y[p in setdiff(Crops, [:beets])] >= 0)
        @recourse(farmer_model, w[s in Crops ∪ [:extra_beets]] >= 0)
        @objective(farmer_model, Min, sum(PurchasePrice[p] * y[p] for p in setdiff(Crops, [:beets]))
                   - sum(SellPrice[s] * w[s] for s in Crops ∪ [:extra_beets]))
        @constraint(farmer_model, minimum_requirement[p in setdiff(Crops, [:beets])],
            ξ[p] * x[p] + y[p] - w[p] >= Required[p])
        @constraint(farmer_model, minimum_requirement_beets,
            ξ[:beets] * x[:beets] - w[:beets] - w[:extra_beets] >= Required[:beets])
        @constraint(farmer_model, beets_quota, w[:beets] <= 6000)
    end
end

# 1. generate all nodes
# 2. generate all arcs
#    a. holdover arcs
#    b. transportation arcs
# 3. ensure zero sum demand

# TODO #3 function to build deterministic model from expanded network
# TODO #16 function to build stochastic model from expanded network