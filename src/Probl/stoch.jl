using StochasticPrograms

@stochastic_model m begin
    @stage 1 begin
        @decision(m, z[a=arcs(basedigraph)], Bin)
        @decision(m, limit[a=arcs(basedigraph)] >= 0, Int)
        @constraint(m, rev[a=arcs(basedigraph)], 
            z[a] == z[reverse(a)]
        )
        @constraint(m, fle[a=arcs(basedigraph)], 
            limit[a] <= basedigraph[a][:limit] * z[a]
        )
        #=@constraint(m, limfle[a=arcs(basedigraph)],
            limit[a] == limit[reverse(a)]
        )=#
        @objective(m, Min, sum(z) + sum(limit))
    end
    @stage 2 begin
        @uncertain demand[n in nodes(expandedgraph)]
        @recourse(m, 0 <= flow[a=arcs(expandedgraph)])
        @recourse(m, 0 <= trip[a=arcs(expandedgraph)] <= expandedgraph[a][:limit], Int)
        @constraint(m, bal[n=nodes(expandedgraph)],
            sum(flow[a] for a in arcs(expandedgraph, :, [n])) - 
            sum(flow[a] for a in arcs(expandedgraph, [n], :)) == demand[n]
        )
        #= @constraint(m, lim_1[a = Nexus.filter_arcs(expandedgraph, :type, :transport)],
            trip[a] >= 1 - expandedgraph[a][:limit] * (1 - z[Arc(src(a).loc, tgt(a).loc, key(a))])
        ) # added =#
        #=@constraint(m, lim_2[a = Nexus.filter_arcs(expandedgraph, :type, :transport)],
            trip[a] <= expandedgraph[a][:limit] * z[Arc(src(a).loc, tgt(a).loc, key(a))]
        ) # added=#
        #=@constraint(m, lim[a=arcs(expandedgraph)],
            trip[a] <= expandedgraph[a][:limit]
        )=#
        @constraint(m, lim[a=Nexus.filter_arcs(expandedgraph, :type, :transport)],
            trip[a] <= limit[Arc(src(a).loc, tgt(a).loc, key(a))]
        )
        @constraint(m, lim_inv[a=Nexus.filter_arcs(expandedgraph, :type, :holdover)],
            trip[a] == 1
        )
        @constraint(m, cap[a=arcs(expandedgraph)], 
            flow[a] <= trip[a] * expandedgraph[a][:Q]
        )
        @objective(m, Min, 
            sum(
                expandedgraph[a][:cpeti] * flow[a] + 
                expandedgraph[a][:cjarak] * expandedgraph[a][:dist] * trip[a]
                for a in arcs(expandedgraph)
            )
        )
    end
end

function demandscenarios(demanddict, N, s)
    result = Scenario[]
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

N = 20 # this far N = 20 sabi
s = 50
newscenarios = demandscenarios(demandlist, N, s)

### PROGRESSIVE HEDGING
new = instantiate(m, newscenarios, optimizer=ProgressiveHedging.Optimizer);

set_optimizer_attribute(new, SubProblemOptimizer(), 
    optimizer_with_attributes(
        Gurobi.Optimizer,
        "OutputFlag" => 0,
        "Threads" => 8,
        "MIPGap" => 0.2
    )
)
set_optimizer_attribute(new, Penalizer(), Adaptive())

optimize!(new)
### PROGRESSIVE HEDGING


### L-SHAPED
new = instantiate(m, newscenarios, optimizer=LShaped.Optimizer);

set_optimizer_attribute(new, MasterOptimizer(), Gurobi.Optimizer)
set_optimizer_attribute(new, SubProblemOptimizer(), Gurobi.Optimizer)
set_optimizer_attribute(new, FeasibilityStrategy(), FeasibilityCuts())
# set_optimizer_attribute(new, IntegerStrategy(), Convexification())

optimize!(new)
### L-SHAPED



cache_solution!(new)

objective_value(new)



ws = WS(new, newscenarios[1])
optimize!(ws)

EVPI(new)
VSS(new)
EEV(new)

val1 = EWS(new)
val2 = VRP(new)

val1-val2

x̄ = expected_value_decision(new)
expected(newscenarios)
x₁ = wait_and_see_decision(new, newscenarios[1])

println(x₁)
sum(x₁)
evaluate_decision(new, x₁)