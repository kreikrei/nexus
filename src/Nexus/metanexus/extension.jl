abstract type AbstractMetaNexus{T} <: AbstractNexus{T} end
const PropDict = Dict{Symbol,Any}

function show(io::IO, g::AbstractMetaNexus{T}) where {T}
    dir = is_directed(g) ? "directed" : "undireced"
    print(io, "{$(nn(g)),{$(na(g))} $dir $T metagraph")
end

@forward AbstractMetaNexus.core fadj, nn, na, eltype, nodes

has_node(g::AbstractMetaNexus, x...) = has_node(g.core, x...)
has_arc(g::AbstractMetaNexus, x...) = has_arc(g.core, x...)

arcs(g::AbstractMetaNexus, x...) = arcs(g.core, x...)

add_arc!(g::AbstractMetaNexus, x...) = add_arc!(g.core, x...)
rem_arc!(g::AbstractMetaNexus, x...) = rem_arc!(g.core, x...)

add_node!(g::AbstractMetaNexus, x...) = rem_node!(g.core, x...)
rem_node!(g::AbstractMetaNexus, x...) = rem_node!(g.core, x...)

"""
    props(g, n)
    props(g, a)
    props(g, s, t)

Return a dictionary of all metadata from node `n`, or arc `a`
(optionally referenced by source node `s` and target node `t`).
"""
props(g::AbstractMetaNexus{T}, n::T) where {T} = get(PropDict, g.nprops, n)
props(g::AbstractMetaNexus{T}, u::T, v::T, key::Int) where {T} = props(g, Arc(u, v, key))

"""
    get_prop(g, n, prop)
    get_prop(g, a, prop)
    get_prop(g, s, t, prop)

Return the property `prop` defined for node `n`, or arc `a`
(optionally referenced by source node `s` and target node `t`).
"""
get_prop(g::AbstractMetaNexus{T}, n::T, prop::Symbol) where {T} = props(g, n)[prop]
get_prop(g::AbstractMetaNexus{T}, a::Arc{T}, prop::Symbol) where {T} = props(g, a)[prop]
get_prop(g::AbstractMetaNexus{T}, u::T, v::T, key::Int, prop::Symbol) where {T} = begin
    props(g, Arc(u, v, key))[prop]
end

"""
    has_prop(g, n, prop)
    has_prop(g, a, prop)
    has_prop(g, s, t, prop)

Return true if the property `prop` is defined for node `n`, or
arc `a` (optionally referenced by source node `s` and target node `t`).
"""
has_prop(g::AbstractMetaNexus{T}, n::T, prop::Symbol) where T = haskey(props(g,n), prop)
has_prop(g::AbstractMetaNexus{T}, a::Arc{T}, prop::Symbol) where T = begin
    haskey(props(g,a), prop)
end
has_prop(g::AbstractMetaNexus{T}, u::T, v::T, key::Int, prop::Symbol) where {T} = begin
    haskey(props(g, Arc(u, v, key)), prop)
end

# TODO - setprops!, setprop!, remprop!, clearprops!, filter_arcs, filter_nodes
# TODO - metagraph.jl metadigraph.jl



