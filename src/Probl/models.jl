function deterministicmodel(expanded::MetaDigraph{locper}, demand::Dict{locper,Int})
    m = Model()

    @variable(m, 0 <= surp[a=arcs(expanded)] <= 1)
    @variable(m, 0 <= trip[a=arcs(expanded)] <= expanded[a][:limit], Int)
    @constraint(m, bal[n=nodes(expanded)],
        sum((trip[a] - surp[a]) * expanded[a][:Q] for a in arcs(expanded, :, [n])) -
        sum((trip[a] - surp[a]) * expanded[a][:Q] for a in arcs(expanded, [n], :)) == demand[n]
    )
    @constraint(m, neg[a=arcs(expanded)], trip[a] - surp[a] >= 0)
    # @constraint(m, cap[a=arcs(expanded)], flow[a] <= trip[a]) # expanded[a][:Q] * 
    # @constraint(m, low[a=arcs(expanded)], flow[a] >= trip[a] - 1)
    # @constraint(m, lim[a=arcs(expanded)], trip[a] <= expanded[a][:limit])
    @objective(m, Min, 
        sum(
            expanded[a][:cpeti] * (trip[a] - surp[a]) * expanded[a][:Q] + 
            expanded[a][:cjarak] * expanded[a][:dist] * trip[a]
            for a in arcs(expanded)
        )
    )

    return m
end

function generatedemand(demand::Dict{locper,Int}, N::Int, s::Int)
    result = Dict{locper,Int}[]
    sizehint!(result, N)

    for _ in 1:N
        new = Dict{locper,Int}()
        for (k,v) in demand
            new[k] = v + rand(-s:s)
        end
        sinkidx = filter(p -> p.loc == vault("SINK"),keys(new)|>collect)
        new[sinkidx[1]] += -sum(values(new))
        push!(result, new)
    end

    return result
end

function deterministicmodel_f(expanded::MetaDigraph{locper}, demand::Dict{locper,Int})
    m = Model()

    @variable(m, 0 <= trip[a=arcs(expanded)] <= expanded[a][:limit], Int)
    @variable(m, 0 <= flow[a=arcs(expanded)])

    @constraint(m, [a=arcs(expanded)], flow[a]/expanded[a][:Q] >= trip[a]-1)
    @constraint(m, [a=arcs(expanded)], flow[a]/expanded[a][:Q] <= trip[a])
    @constraint(m, bal[n=nodes(expanded)],
        sum(flow[a] for a in arcs(expanded, :, [n])) -
        sum(flow[a] for a in arcs(expanded, [n], :)) == demand[n]
    )

    periods = [d.per for d in keys(demand)] |> unique!
    locations = [d.loc for d in keys(demand)] |> unique!

    nodesonper(t) = filter(p -> p.per == t, nodes(expanded) |> collect)
    nodesonloc(v) = filter(p -> p.loc == v, nodes(expanded) |> collect)

    @constraint(m, t_cut[t=periods],
        sum(flow[a] for a in arcs(expanded, :, nodesonper(t))) -
        sum(flow[a] for a in arcs(expanded, nodesonper(t), :)) == 
        sum(demand[n] for n in nodesonper(t))
    )
    @constraint(m, l_cut[l=locations],
        sum(flow[a] for a in arcs(expanded, :, nodesonloc(l))) -
        sum(flow[a] for a in arcs(expanded, nodesonloc(l), :)) == 
        sum(demand[n] for n in nodesonloc(l))
    )

    @objective(m, Min, 
        sum(
            expanded[a][:cpeti] * flow[a] + 
            expanded[a][:cjarak] * expanded[a][:dist] * trip[a]
            for a in arcs(expanded)
        )
    )

    return m
end