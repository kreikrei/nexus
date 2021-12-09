struct ArcIter{T} <: AbstractArcIter{T}
    list::Vector{Arc{T}}
end

ArcIter(list::Vector{Arc{T}}) where {T} = ArcIter{T}(list)

@forward ArcIter.list iterate, eltype, length

function arcs(g::Graph{T}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for (u,nbr) in g.fadj, (v,keylist) in nbr, (key,fin) in keylist
        Arc(v, u, key) in list || push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function arcs(g::Graph{T}, n::Union{T,Vector{T}}) where {T}
    # all arc adjacent to n in UNDIRECTED Graph
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for u in n, (v,keylist) in g.fadj[u], (key,fin) in keylist
        Arc(v, u, key) in list || push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function arcs(g::Digraph{T}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for (u,nbr) in g.fadj, (v,keylist) in nbr, (key,fin) in keylist
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function arcs(g::Digraph{T}, n::Union{T,Vector{T}}, ::Colon) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for u in n, (v,keylist) in g.fadj[u], (key,fin) in keylist
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function arcs(g::Digraph{T}, ::Colon, n::Union{T,Vector{T}}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for v in n, (u,keylist) in g.badj[v], (key,fin) in keylist
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end