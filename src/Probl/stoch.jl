
@stochastic_model m begin
    @stage 1 begin
        @decision(m, z[a=arcs(basedigraph)], Bin)
        @constraint(m, rev[a=arcs(basedigraph)], z[a] == z[reverse(a)])
        @objective(m, Min, sum(z))
    end
    @stage 2 begin
        @uncertain demand[n in nodes(expandedgraph)]
        @recourse(m, 0 <= surp[a=arcs(expandedgraph)] <= 1)
        @recourse(m, 0 <= trip[a=arcs(expandedgraph)], Int)
        @constraint(m, bal[n=nodes(expandedgraph)],
            sum((trip[a] - surp[a]) * expandedgraph[a][:Q] for a in arcs(expandedgraph, :, [n])) -
            sum((trip[a] - surp[a]) * expandedgraph[a][:Q] for a in arcs(expandedgraph, [n], :)) == demand[n]
        )
        @constraint(m, neg[a=arcs(expandedgraph)], trip[a] - surp[a] >= 0)
        @constraint(m, lim[a=arcs(expandedgraph)],trip[a] <= expandedgraph[a][:limit])
        @constraint(m, lim_1[a = Nexus.filter_arcs(expandedgraph, :type, :transport)],
            trip[a] >= 1 - expandedgraph[a][:limit] * (1 - z[Arc(src(a).loc, tgt(a).loc, key(a))])
        ) # added
        @constraint(m, lim_2[a = Nexus.filter_arcs(expandedgraph, :type, :transport)],
            trip[a] <= expandedgraph[a][:limit] * z[Arc(src(a).loc, tgt(a).loc, key(a))]
        ) # added
        
        @objective(m, Min, 
            sum(
                expandedgraph[a][:cpeti] * (trip[a] - surp[a]) * expandedgraph[a][:Q] + 
                expandedgraph[a][:cjarak] * expandedgraph[a][:dist] * trip[a]
                for a in arcs(expandedgraph)
            )
        )
    end
end

function demandscenarios(demanddict, N, s)
    result = Scenario{JuMP.Containers.DenseAxisArray{Int64, 1, Tuple{Base.KeySet{locper, Dict{locper, Dict{locper, Dict{Int64, Nothing}}}}}, Tuple{JuMP.Containers._AxisLookup{Dict{locper, Int64}}}}}[]
    for _ in 1:N
        list = Dict(
            k => v + rand(-s:s) 
            for (k,v) in demanddict
        )
        list[locper(vault("SINK"),13)] += -sum(values(list))
        new = @scenario demand[n in nodes(expandedgraph)] list[n] probability=1/N
        push!(result, new)
    end
    return result
end

N = 20
s = 10
newscenarios = demandscenarios(demandlist, N, s)

new = instantiate(m, newscenarios, optimizer=ProgressiveHedging.Optimizer)

set_optimizer_attributes(new, 
    "Threads" => 8,
    "MIPGap" => 0.5
)

set_optimizer_attribute(new, MasterOptimizer(), 
    optimizer_with_attributes(
        Gurobi.Optimizer,
        "OutputFlag" => 0,
        "Threads" => 8,
        "MIPGap" => 0.6,
        "Presolve" => 2,
        "Cuts" => 2
    )
)
set_optimizer_attribute(new, SubProblemOptimizer(), 
    optimizer_with_attributes(
        Gurobi.Optimizer,
        "OutputFlag" => 0,
        "Threads" => 8,
        "MIPGap" => 0.6,
        "Presolve" => 2,
        "Cuts" => 2
    )
)
set_optimizer_attribute(new, PrimalTolerance(), 0.4)

set_optimizer_attribute(new, FeasibilityStrategy(), FeasibilityCuts())
set_optimizer_attribute(new, IntegerStrategy(), CombinatorialCuts())
set_optimizer_attribute(new, Regularizer(), LevelSet())
set_optimizer_attribute(new, Consolidator(), Consolidate())
# set_optimizer_attribute(new, Aggregator(), PartialAggregate(46))


# set_optimizer_attribute(new, "Threads", 8)

optimize!(new)
objective_value(new)
ws = WS(new, demand_1)
print(ws)

x₁ = wait_and_see_decision(new, demand_1)

println(x₁)
evaluate_decision(new, x₁)