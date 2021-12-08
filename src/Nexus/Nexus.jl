using SimpleTraits
using Lazy

import Base:
    show, eltype, Tuple, iterate, length

include("interface.jl")
include("digraph.jl")
include("graph.jl")
include("arc.jl")
include("arciter.jl")


D = Digraph{String}()
add_arc!(D, "Jakarta", "Ambon")
add_arc!(D, "Ambon", "Medan")
add_arc!(D, "Ambon", "Medan", 100)
add_arc!(D, "Medan", "Ambon")
D.fadj
D

Arc("Medan","Bandung")
Arc("Medan", "Bandung", 3)

rem_arc!(D, "Jakarta", "Ambon")
D.fadj["Jakarta"]
D
D.fadj


G = Graph{String}()
add_arc!(G, "a", "b")
add_arc!(G, "b", "a", 2)
add_arc!(G, "a", "b", 100)
add_arc!(G, "b", "c")
G.fadj
G

G.fadj

rem_arc!(G, "a", "b")

n = copy(G.fadj)
m = copy(G.fadj)

newD = Digraph(G.nn, G.na, n, m)

newD.fadj
newD.badj


add_arc!(newD, "c", "a")

newD.fadj
newD.badj

function flatten(d::Dict, prevpath::Vector = [])
    items = Vector[]
    for (k, v) in d
        nextpath = vcat(prevpath, k)
        v isa Dict ? append!(items, flatten(v, nextpath)) : push!(items, nextpath)
    end
    return items
end



tes1 = generate_random(Graph, 1000)
tes2 = generate_random(Graph, 1000)

flatfor(tes1.fadj)

G = Graph{Int}()
N = 100

add_arc!(G, rand(1:N), rand(1:N))

same = rand(1:N)
add_arc!(G, same, same)

G
flattne = flatfor(G.fadj)

println(flattne)

println(tes1.fadj)

function flatfor(d::Dict)
    result = Vector[]
    for (u, nbr) in d
        for (v, key) in nbr
            for (k, fin) in key
                push!(result, [u, v, k])
            end
        end
    end
    return result
end

using BenchmarkTools


@benchmark flatten(tes1.fadj)

@benchmark flatfor(tes1.fadj)

# ARCiter

a = [3,7]
iterate(a)
Base.eltype(a)
Base.iterate

G = Graph{Int}()

add_arc!(G,2,5)

tesait = ArcIter(G,[2,3,4,1])

for a in tesait
    println(a)
end

tesait.list

G.fadj
TP = deepcopy(G.fadj)
copyofG = Graph(G.nn,G.na,TP)
result = Arc{eltype(G)}[]

for (u,nbr) in copyofG.fadj, (v,key) in nbr, (k,fin) in key
    if !(Arc(v,u,k) in result)
        push!(result, Arc(u,v,k))
    end
end

result

flatfor(copyofG.fadj)

D = Digraph{Int}()

for i in 1:100, j in 1:100
    add_arc!(D, rand(1:100), rand(1:100))
end

allarc = ArcIter(D)
@code_warntype ArcIter(D)

iterate(allarc)

eltype(allarc)
length(allarc)

in65 = ArcIter(D, :, 65)

in65.list ⊆ allarc.list


for a in ArcIter(D, :, 65)
    println(a)
end