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

generatedemands(d::Dict{locper,Int}, s::Int, N::Int) = [
    typeof(d)(k => v + rand(-s:s) for (k,v) in d) for _ in 1:N
]

function expand(basedigraph::MetaDigraph{vault}, _demandlist::Dict{locper,Int})
    expanded = MetaDigraph{locper}()
    demandlist = Dict{locper,Int}(k => v for (k,v) in _demandlist)
    
    periods = map(p -> p.per, keys(demandlist) |> collect)
    T_min = findmin(periods) |> first
    T_max = findmax(periods) |> first

    sink = locper(vault("SINK"), T_max + 1)
    add_node!(expanded, sink) # add sink
    
    for i in nodes(basedigraph), t in T_min:T_max
        u = locper(i, t)
        v = t === T_max ? sink : locper(i, t + 1)
        k = add_arc!(expanded, u, v)
        set_prop!(expanded, u, v, k, :type, :holdover)
    end # all vaults, all periods, holdover arcs
    
    for a in arcs(basedigraph), t in T_min:T_max
        t_tgt = t + basedigraph[a][:transit]
        if t_tgt <= T_max
            u = locper(src(a), t)
            v = locper(tgt(a), t_tgt)
            k = add_arc!(expanded, u, v, key(a))
            set_prop!(expanded, u, v, k, :type, :transport)
        end
    end # all arcs, all periods, transport arc

    for n in nodes(expanded)
        haskey(demandlist, n) || (demandlist[n] = 0)
    end # sink added as zero demand value
    differ = values(demandlist) |> sum
    differ != 0 && (demandlist[sink] = -differ)

    for a in arcs(expanded)
        if expanded[a][:type] == :transport
            a_ = Arc(src(a).loc, tgt(a).loc, key(a))
            set_prop!(expanded, a, :cjarak, basedigraph[a_][:cjarak])
            set_prop!(expanded, a, :cpeti, basedigraph[a_][:cpeti])
            set_prop!(expanded, a, :limit, basedigraph[a_][:limit])
            set_prop!(expanded, a, :dist, basedigraph[a_][:dist])
            set_prop!(expanded, a, :Q, basedigraph[a_][:Q])
        elseif expanded[a][:type] == :holdover
            n = src(a).loc
            set_prop!(expanded, a, :cjarak, 0)
            set_prop!(expanded, a, :cpeti, 0)
            set_prop!(expanded, a, :limit, 1)
            set_prop!(expanded, a, :dist, 0)
            set_prop!(expanded, a, :Q, basedigraph[n][:cap])
        end
    end

    for n in nodes(expanded)
        Nexus.clear_props!(expanded, n)
    end

    return expanded, demandlist
end