workdir = pwd()

refpath = "$workdir/src/Nexus"
push!(LOAD_PATH, refpath)

using Revise
using Nexus
using Random

MD = MetaGraph{Int}()
N = 10
for _ in 1:N
    add_arc!(MD, Arc(rand(1:N), rand(1:N), rand(1:N)))
    add_arc!(MD, Arc(rand(1:N), rand(1:N)))
    add_arc!(MD, rand(1:N), rand(1:N), rand(1:N))
    add_arc!(MD, rand(1:N), rand(1:N))
end

for a in arcs(MD)
    set_prop!(MD, a, :weight, rand(1:10))
    set_props!(MD, a, Dict(:dist => rand(100:1000), :cost=> rand()))
    set_prop!(MD, src(a), tgt(a), key(a), :opt, rand(1:5))
end

for n in nodes(MD)
    set_prop!(MD, n, :name, randstring(N))
    set_props!(MD, n, Dict(:cap => rand(1:100), :coo => (x = rand(1:1000), y = rand(1:1000))))
end

tesnode = rand(nodes(MD))
props(MD, tesnode)

tesarc = rand(arcs(MD))
props(MD, tesarc)

rem_prop!(MD, 2, :cap)
props(MD, 2)

filter_nodes(MD, :name) |> collect
clear_props!(MD, 3)

filter_arcs(MD, (g, a) -> has_prop(g, a, :dist) && get_prop(g, a, :dist) >= 600) |> collect
arcs(MD, :, 2) |> collect
nodes(MD) |> collect

props(MD, Arc(5,2,1))
MD

arcs(MD) |> collect
arcs(MD, :, 1) |> collect
arcs(MD) |> collect
MD[8,1,10][:cost]
has_node(MD,1)

fadj(MD)
nn(MD)
na(MD)
eltype(MD)
nodes(MD)

set_prop!(MD, 2,3,1, :moda, "truk")
props(MD, 2,3,1)

has_node(MD,2)

G = Graph{Int}()

for i in 1:5, j in 1:5
    add_arc!(G, rand(1:5), rand(1:5))
end

G 
length(G.fadj[2][5])

arcs(G)
arcs(G) |> collect|> println

arcs(G, 2) |> collect



rem_node!(G, 2)
G
arcs(G)
arcs(G) |> collect

G.fadj

Digraph(G).fadj

2 => 2 (1)
2 => 3 (2)
2 => 1 (4)
1 => 1 (1)
3 => 1 (1)

D = Digraph{Int}()
N = 10
for i in 1:N, j in 1:N
    add_arc!(D, rand(1:N), rand(1:N))
end
D
arcs(D)
arcs(D) |> collect

predicted = D.na - length(union(
    arcs(D,2,:) |> collect,
    arcs(D,:,2) |> collect
))

rem_node!(D,2)
D

predicted == D.na

isempty(Iterators.filter(p -> tgt(p) == 2, arcs(D)) |> collect)
isempty(Iterators.filter(p -> src(p) == 2, arcs(D)) |> collect)
filter

D.badj

arcs(D,6,:) |> collect

has_arc(D,Arc(1,6,4))
has_node(D,11)

arcs(D)
reduce