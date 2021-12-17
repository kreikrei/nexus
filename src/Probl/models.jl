function deterministicmodel(expanded::MetaDigraph{locper}, demand::Dict{locper,Int})
    m = Model()

    @variable(m, 0 <= flow[a=arcs(expanded)], Int)
    @variable(m, 0 <= trip[a=arcs(expanded)], Int)
    @constraint(m, bal[n=nodes(expanded)],
        sum(flow[a] for a in arcs(expanded, :, [n])) -
        sum(flow[a] for a in arcs(expanded, [n], :)) == demand[n]
    )
    @constraint(m, cap[a=arcs(expanded)], flow[a] <= expanded[a][:Q] * trip[a])
    @constraint(m, lim[a=arcs(expanded)], trip[a] <= expanded[a][:limit])
    @objective(m, Min, 
        sum(
            expanded[a][:cpeti] * flow[a] + 
            expanded[a][:cjarak] * expanded[a][:dist] * trip[a]
            for a in arcs(expanded)
        )
    )

    return m
end