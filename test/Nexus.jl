workdir = pwd()

refpath = "$workdir/src/Nexus"
push!(LOAD_PATH, refpath)

using Revise
using Nexus

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
N = 100
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