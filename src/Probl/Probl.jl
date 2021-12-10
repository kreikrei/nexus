# defines problem structures and its conversion process from raw data

include("$(pwd())/src/Nexus/Nexus.jl")

using CSV
using DataFrames
using Distances

# khazanah_id => String

# spacetime => khazanah_id + period

struct vault
    name::String
end

struct locper
    loc::vault
    per::Int
end


khazanah = CSV.File("$(pwd())/data/khazanah-master.csv") |> DataFrame
trayek = CSV.File("$(pwd())/data/trayek-usulan-essence.csv") |> DataFrame
moda = CSV.File("$(pwd())/data/moda-hasil-estim copy.csv") |> DataFrame

modadict = Dict(m.id => Dict(
    :name => m.name,
    :Q => m.Q,
    :var => m.var,
    :dis => m.dis,
    :transit => m.transit
 ) for m in eachrow(moda))

translatedict = Dict( m.name => m.id for m in eachrow(moda))
    

G = Nexus.Graph{vault}()
map(t -> Nexus.add_arc!(G, vault(t.u), vault(t.v), translatedict[t.moda]),eachrow(trayek))
D = Nexus.Digraph(G)

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




