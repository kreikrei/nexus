mutable struct MetaDigraph{T} <: AbstractMetaNexus{T}
    core::Digraph{T}
    nprops::Dict{T,PropDict}
    aprops::Dict{Arc{T},PropDict}
end

MetaDigraph(core::Digraph{T}) where {T} =
    MetaDigraph{T}(core, Dict{T,PropDict}(), Dict{Arc{T},PropDict}())
MetaDigraph{T}() where {T} = MetaDigraph(Digraph{T}())

is_directed(::MetaDigraph) = true

@forward MetaDigraph.core badj
props(g::MetaDigraph, a::Arc) = get(PropDict, g.aprops, a)

Digraph(g::MetaDigraph{T}) where {T} = g.core

function set_props!(g::MetaDigraph{T}, a::Arc{T}, d::Dict) where {T}
    if has_arc(g, a)
        !_hasdict(g, a) ? g.aprops[a] = d : merge!(g.aprops[a], d)
        return true
    else
        return false
    end
end

rem_prop!(g::MetaDigraph{T}, a::Arc{T}, prop::Symbol) where {T} =
    delete!(g.aprops[a], prop)