function deterministicmodel(expanded::MetaDigraph{locper}, demand::Dict{locper,Int})
    m = Model()

    @variable(m, 0 <= flow[a=arcs(expanded)])
    @variable(m, 0 <= trip[a=arcs(expanded)] <= expanded[a][:limit], Int)
    @constraint(m, bal[n=nodes(expanded)],
        sum(flow[a] for a in arcs(expanded, :, [n])) - 
        sum(flow[a] for a in arcs(expanded, [n], :)) == demand[n]
    )
    @constraint(m, cap[a=arcs(expanded)], flow[a] <= trip[a] * expanded[a][:Q])
    @objective(m, Min, 
        sum(
            expanded[a][:cpeti] * flow[a] + 
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