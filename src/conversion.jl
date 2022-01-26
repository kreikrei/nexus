# transform graph into adjacency matrix
using AxisArrays
N = nodes(sol) |> length

A = AxisArray(zeros(N,N), 
    Axis{:src}(nodes(sol)|>collect), 
    Axis{:tgt}(nodes(sol)|>collect)
)

for a in arcs(sol)
    A[src(a),tgt(a)] += sol[a][:flow]
end
A.data
plot(z=A.data, Geom.contour)

outdeg = eachrow(A) |> sum
indeg = eachcol(A) |> sum

outdf = DataFrame(loc=[n.loc.name for n in collect(nodes(sol))], 
    per=[n.per for n in collect(nodes(sol))],
    val=outdeg
)

indf = DataFrame(loc=[n.loc.name for n in collect(nodes(sol))], 
    per=[n.per for n in collect(nodes(sol))],
    val=indeg
)

finalout = filter(p-> p.loc != "SINK",outdf)
finalin = filter(p-> p.loc != "SINK", indf)

using Gadfly
using Cairo
using Fontconfig
using Random

id = randstring(4)

p_out = plot(finalout, x=:per, y=:loc, color=:val, Geom.rectbin)
draw(PNG("p_out$id.png"),p_out)

p_in = plot(finalin, x=:per, y=:loc, color=:val, Geom.rectbin)
draw(PNG("p_in$id.png"),p_in)