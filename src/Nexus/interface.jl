abstract type AbstractNexus{T} end
abstract type AbstractArc{T} end
abstract type AbstractArcIter{T} end

@traitdef IsDirected{G<:AbstractNexus}
@traitimpl IsDirected{G} <- is_directed(G)

function show(io::IO, g::AbstractNexus{T}) where {T}
    dir = is_directed(g) ? "directed" : "undirected"
    print(io, "{$(nn(g)), $(na(g))} $dir $T graph.")
end

function show(io::IO, a::AbstractArc{T}) where {T}
    val = isnothing(a.key) ? "=" : key(a)
    print(io, "Arc $T $(src(a)) =$val=> $(tgt(a))")
end

function show(io::IO, ait::AbstractArcIter{T}) where {T}
    print(io, "ArcIter $T $(length(ait.list))")
end

nn(g::AbstractNexus) = g.nn
na(g::AbstractNexus) = g.na

src(a::AbstractArc) = a.src
tgt(a::AbstractArc) = a.tgt
key(a::AbstractArc) = a.key
