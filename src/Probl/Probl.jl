# defines problem structures and its conversion process from raw data
include("$(pwd())/src/Nexus/Nexus.jl")
include("forwarding.jl")

using CSV
using DataFrames
using Distances

struct vault
    name::String
end

Base.show(io::IO, v::vault) = print(io,"$(v.name)")

struct locper
    loc::vault
    per::Int
end

Base.show(io::IO, lp::locper) = print(io,"⟦i=$(lp.loc),t=$(lp.per)⟧")

khazanah = CSV.File("$(pwd())/data/khazanah-master.csv") |> DataFrame
trayek = CSV.File("$(pwd())/data/trayek-usulan-essence.csv") |> DataFrame
moda = CSV.File("$(pwd())/data/moda-hasil-estim copy.csv") |> DataFrame

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

    # add all arc to undirected + compute distance
    for r in eachrow(trayek)
        a = Nexus.Arc(vault(r.u), vault(r.v), modamap[r.moda])
        add_arc!(G, a)
        set_props!(G, a, Dict(pairs(modalookup[key(a)]) |> collect))
        set_prop!(G, a,:dist, haversine(G[src(a)][:coo],G[tgt(a)][:coo],6372))
    end

    return G
end

basenet = baseGraph(khazanah, trayek, moda)

# transform undirected to directed
D = MetaDigraph{vault}()

# add nodes and attrib of undirected to directed
for n in Nexus.nodes(G)
    Nexus.add_node!(D,n)
    Nexus.set_props!(D,n,G[n])
end

for a in Nexus.arcs(G)
    Nexus.add_arc!(D,a)
    Nexus.set_props!(D,a,G[a])
    Nexus.add_arc!(D,reverse(a))
    Nexus.set_props!(D,reverse(a),G[a])
end


# node attrib prep
D
for a in Nexus.arcs(D)
    println("$a -> $(D[a][:dist])")
end

D[vault("Jakarta")]

D[Nexus.Arc(vault("Medan"), vault("Jakarta"), modamap["KPNG"])]
G[Nexus.Arc(vault("Medan"), vault("Jakarta"), modamap["KPNG"])]

nodeprop = Dict{vault,Dict{Symbol,Any}}()
sizehint!(nodeprop, D.nn)
map(r -> setindex!(nodeprop,Dict(
            :coo => (x = r.x, y = r.y),
            :cap => r.MAX
        ),
        vault(r.name)
    ),
    eachrow(khazanah)
)

for r in eachrow(khazanah)
    nodeprop[vault(r.name)] = Dict(
        :coo => (x = r.x, y = r.y),
        :cap => r.MAX
    )
end

arcprop = Dict{Nexus.Arc{vault},Dict{Symbol,Any}}()
sizehint!(arcprop, D.na)
for a in Nexus.arcs(D)
    arcprop[a] = modadict[Nexus.key(a)]
    arcprop[a][:dist] = haversine(nodeprop[Nexus.src(a)][:coo],nodeprop[Nexus.tgt(a)][:coo])/1000
end

BASENET = BaseNetwork(D,nodeprop,arcprop)

Base.show(io::IO, bn::BaseNetwork) = show(io, bn.core)
Base.getindex(bn::BaseNetwork, a::Nexus.Arc{vault}, s::Symbol) = bn.aprops[a][s]

BASENET[Nexus.Arc(vault("Jakarta"),vault("Makassar"),1011),:dis]
BASENET.nprops
BASENET.aprops[Nexus.Arc(vault("Jakarta"),vault("Makassar"),1011)]




