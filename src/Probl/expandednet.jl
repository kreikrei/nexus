struct locper
    loc::vault
    per::Int
end

Base.show(io::IO, lp::locper) = print(io,"⟦i=$(lp.loc),t=$(lp.per)⟧")

function demands(demandlist::DataFrame)
    D = Dict{locper,Int}()

    for i = 1:ncol(demandlist)
        for t = 1:nrow(demandlist)
            k = locper(names(demandlist)[i] |> vault, t - 1) # start dr t = 0
            v = demandlist[t, i]
            D[k] = v
        end
    end

    return D
end

generatedemands(d::Dict{locper,Int}, s::Int, N::Int) = map(
    () -> typeof(d)(k => v + rand(-s:s) for (k,v) in d) , 1:N
)

function expand(basedigraph::MetaDigraph{vault}, demandlist::Dict{locper,Int})
    periods = map(p -> p.per, keys(demandlist) |> collect)
    T_min = findmin(periods) |> first
    T_max = findmax(periods) |> first # update t_min t_max

    expanded = MetaDigraph{locper}()
    for i in nodes(basedigraph), t = T_min:T_max
        n0 = locper(i, t)
        n1 = locper(i, t + 1)

        add_node!(expanded, n0)
        set_props!(expanded, n0, Dict(k => v for (k, v) in basedigraph[i])) # Q

        k = add_arc!(expanded, Arc(n0, n1))
        set_prop!(expanded, Arc(n0, n1, k), :type, :holdover)
    end # all vault from base, all period from demand list, holdover arcs
    for a in arcs(basedigraph), t = T_min:T_max
        u = locper(src(a), t)
        v = locper(tgt(a), t + basedigraph[a][:transit])
        k = key(a)
        
        transport = Arc(u, v, k)
        add_arc!(expanded, transport)
        set_prop!(expanded, transport, :type, :transport)
    end # all arcs, all periods, transport arc

    map(n -> haskey(demandlist, n) || (demandlist[n] = 0), nodes(expanded) |> collect) # complete

    periods = map(p -> p.per, keys(demandlist) |> collect)
    T_min = findmin(periods) |> first
    T_max = findmax(periods) |> first # update t_min t_max

    differ = sum(values(demandlist))
    if differ != 0
        sink_node = locper(vault("SINK"), T_max + 1)
        add_node!(expanded, sink_node)
        demandlist[sink_node] = -differ
        for i in nodes(basedigraph)
            k = add_arc!(expanded, Arc(locper(i, T_max), sink_node))
            set_prop!(expanded, Arc(locper(i, T_max), sink_node, k), :type, :holdover)
        end
    end # arcs to dummy sink

    for a in arcs(expanded)
        if expanded[a][:type] == :transport
            ori_a = Arc(src(a).loc, tgt(a).loc, key(a))
            # add transport attrib
            set_prop!(expanded, a, :cjarak, basedigraph[ori_a][:cjarak])
            set_prop!(expanded, a, :cpeti, basedigraph[ori_a][:cpeti])
            set_prop!(expanded, a, :limit, basedigraph[ori_a][:limit])
            set_prop!(expanded, a, :Q, basedigraph[ori_a][:Q])
            set_prop!(expanded, a, :dist, basedigraph[ori_a][:dist])
        elseif expanded[a][:type] == :holdover
            n = src(a).loc
            # add holdover attrib
            set_prop!(expanded, a, :cjarak, 0)
            set_prop!(expanded, a, :cpeti, 0)
            set_prop!(expanded, a, :limit, 1)
            set_prop!(expanded, a, :Q, basedigraph[n][:cap])
            set_prop!(expanded, a, :dist, 0)
        end
    end

    for n in nodes(expanded)
        Nexus.clear_props!(expanded, n)
    end

    return expanded
end