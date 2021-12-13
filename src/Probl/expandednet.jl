struct locper
    loc::vault
    per::Int
end

Base.show(io::IO, lp::locper) = print(io,"⟦i=$(lp.loc),t=$(lp.per)⟧")

function demands(demandlist::DataFrame)
    D = Dict{locper, Int}()

    for i in 1:ncol(demandlist)
        for t in 1:nrow(demandlist)
            k = locper(names(demandlist)[i] |> vault, t-1) # start dr t = 0
            v = demandlist[t,i]
            D[k] = v
        end
    end

    return D
end

function generatedemands(d::Dict{locper,Int}, s::Int, N::Int)
    return [typeof(d)(k => v + rand(-s:s) for (k,v) in d) for _ in 1:N]
end

function expand(basedigraph::MetaDigraph{vault}, demandlist::Dict{locper,Int})
    T_min = findmin([lp.per for lp in keys(demandlist)]) |> first
    T_max = findmax([lp.per for lp in keys(demandlist)]) |> first

    expanded = MetaDigraph{locper}()
    for i in nodes(basedigraph), t in T_min:T_max
        add_node!(expanded, locper(i,t))
        set_props!(expanded, locper(i,t), Dict(k => v for (k,v) in basedigraph[i])) # Q
        if t+1 <= T_max
            k = add_arc!(expanded, Arc(locper(i,t),locper(i,t+1)))
            set_prop!(expanded, Arc(locper(i,t),locper(i,t+1),k), :type, :holdover)
        end
    end # all vault from base, all period from demand list, holdover arcs

    for a in arcs(basedigraph), t in T_min:T_max
        tgt_per = t + basedigraph[a][:transit]
        if tgt_per <= T_max
            transport = Arc(locper(src(a),t), locper(tgt(a),tgt_per), key(a))
            add_arc!(expanded, transport)
            set_prop!(expanded, transport, :type, :transport)
        end
    end # all arcs, all periods, transport arc
    
    differ = sum(values(demandlist))
    if differ != 0
        sink_node = locper(vault("SINK"),T_max+1)
        add_node!(expanded, sink_node)
        demandlist[sink_node] = -differ
        for i in nodes(basedigraph)
            k = add_arc!(expanded, Arc(locper(i,T_max),sink_node))
            set_prop!(expanded, Arc(locper(i,T_max),sink_node,k), :type, :holdover)
        end
    end # arcs to dummy sink

    for a in arcs(expanded)
        if expanded[a][:type] == :transport
            ori_a = Arc(src(a).loc,tgt(a).loc,key(a))
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