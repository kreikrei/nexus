struct ArcIter{T} <: AbstractArcIter{T}
    list::Vector{Arc{T}}
end

ArcIter(list::Vector{Arc{T}}) where {T} = ArcIter{T}(list)

@forward ArcIter.list iterate, eltype, length

function ArcIter(g::Graph{T}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for u in keys(g.fadj), v in keys(g.fadj[u]), key in keys(g.fadj[u][v])
        Arc(v, u, key) in list || push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function ArcIter(g::Graph{T}, n::Union{T,Vector{T}}) where {T}
    # all arc adjacent to n in UNDIRECTED Graph
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for u in n, v in keys(g.fadj[u]), key in keys(g.fadj[u][v])
        Arc(v, u, key) in list || push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function ArcIter(g::Digraph{T}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for u in keys(g.fadj), v in keys(g.fadj[u]), key in keys(g.fadj[u][v])
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function ArcIter(g::Digraph{T}, n::Union{T,Vector{T}}, ::Colon) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for u in n, v in keys(g.fadj[u]), key in keys(g.fadj[u][v])
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end

function ArcIter(g::Digraph{T}, ::Colon, n::Union{T,Vector{T}}) where {T}
    list = Arc{T}[]
    sizehint!(list, g.na)
    @inbounds for v in n, u in keys(g.badj[v]), key in keys(g.badj[v][u])
        push!(list, Arc(u, v, key))
    end
    return ArcIter(list)
end