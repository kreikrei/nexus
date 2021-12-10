mutable struct MetaGraph{T} <: AbstractMetaNexus{T}
    core::Graph{T}
    nprops::Dict{T, PropDict}
    aprops::Dict{Arc{T}, PropDict}
end

MetaGraph(core::Graph{T}) where T = MetaGraph{T}(core, Dict{T, PropDict}(), Dict{Arc{T}, PropDict}())
MetaGraph{T}() where T = MetaGraph(Graph{T}())

is_directed(::MetaGraph) = false

props(g::MetaGraph, a::Arc) = 
    merge(get(PropDict, g.aprops, a), get(PropDict, g.aprops, reverse(a)))

Graph(g::MetaGraph{T}) = g.core

function set_props!(g::MetaDigraph{T}, a::Arc{T}, d::PropDict)
    if has_arc(g, a)
        _hasdict(g, a) ? merge!(g.aprops[a], d) : begin
            _hasdict(g, reverse(a)) ? merge!(g.aprops[reverse(a)], d) : g.aprops[a] = d
        end
        return true
    else
        return false
    end
end

function rem_prop!(g::MetaDigraph{T}, a::Arc{T}, prop::Symbol) where T
    _hasdict(g, a) && delete!(g.aprops[a], prop)
    _hasdict(g, reverse(a)) && delete!(g.aprops[reverse(a)], prop)
end