struct vault
    name::String
end

Base.show(io::IO, v::vault) = print(io,"$(v.name)")

# transform khazanah trayek and moda into undirected graph
function baseGraph(khazanah::DataFrame, trayek::DataFrame, moda::DataFrame)
    G = MetaGraph{vault}()

    # add all node 
    for n in eachrow(khazanah)
        add_node!(G, vault(n.name))
        set_props!(G, vault(n.name), Dict(:coo => (x = n.x, y = n.y), :cap => n.MAX))
    end

    # arc attrib prep
    modalookup = Dict(pairs(eachrow(moda)))
    modamap = Dict(reverse.(pairs(moda.name)|>collect))
    for r in eachrow(trayek)
        a = Arc(vault(r.u), vault(r.v), modamap[r.moda])
        add_arc!(G, a)
        set_props!(G, a, Dict(pairs(modalookup[key(a)]) |> collect))
        set_prop!(G, a,:dist, haversine(G[src(a)][:coo],G[tgt(a)][:coo],6372))
    end

    return G
end

# transform undirected to directed
baseDigraph(mg::MetaGraph{vault}) = MetaDigraph(
    Digraph(Graph(mg)), 
    Dict(k => v for (k,v) in mg.nprops), 
    Dict(k => v for (k,v) in mg.aprops)
)