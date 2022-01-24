using StochasticPrograms

@stochastic_model m begin
    @stage 1 begin
        @decision(m, limit[a=arcs(basedigraph)] >= 0, Int)
    end
    @stage 2 begin
        @uncertain demand[n in nodes(expandedgraph)]
        @recourse(m, 0 <= flow[a=arcs(expandedgraph)])
        @recourse(m, 0 <= trip[a=arcs(expandedgraph)], Int)
        
        @constraint(m, bal[n=nodes(expandedgraph)],
            sum(flow[a] for a in arcs(expandedgraph, :, [n])) - 
            sum(flow[a] for a in arcs(expandedgraph, [n], :)) == demand[n]
        )
        @constraint(m, cap[a=arcs(expandedgraph)],
            flow[a] <= trip[a] * expandedgraph[a][:Q]
        )

        @constraint(m, lim_trans[a=Nexus.filter_arcs(expandedgraph, :type, :transport)],
            trip[a] <= limit[Arc(src(a).loc, tgt(a).loc, key(a))]
        )
        @constraint(m, lim_inv[a=Nexus.filter_arcs(expandedgraph, :type, :holdover)],
            trip[a] == 1
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

@stochastic_model m begin
    @stage 1 begin
        @variable(m, limit[a=arcs(basedigraph)] >= 0)
        @decision(m, trip[a=arcs(expandedgraph)] >= 0, Int)
        @constraint(m, trans[a=Nexus.filter_arcs(expandedgraph, :type, :transport)], 
            trip[a] <= limit[Arc(src(a).loc, tgt(a).loc, key(a))]
        )
        @constraint(m, inventory[a=Nexus.filter_arcs(expandedgraph, :type, :holdover)],
            trip[a] <= 1
        )
        @objective(m, Min, 
            sum(
                expandedgraph[a][:cjarak] * expandedgraph[a][:dist] * trip[a]
                for a in arcs(expandedgraph)
            )
        )
    end
    @stage 2 begin
        @uncertain demand[n in nodes(expandedgraph)]
        @recourse(m, 0 <= flow[a=arcs(expandedgraph)])
        @constraint(m, bal[n=nodes(expandedgraph)],
            sum(flow[a] for a in arcs(expandedgraph, :, [n])) - 
            sum(flow[a] for a in arcs(expandedgraph, [n], :)) == demand[n]
        )
        @constraint(m, cap[a = arcs(expandedgraph)],
            flow[a] <= trip[a] * expandedgraph[a][:Q]
        )
        @objective(m, Min, 
            sum(
                expandedgraph[a][:cpeti] * flow[a]
                for a in arcs(expandedgraph)
            )
        )
    end
end