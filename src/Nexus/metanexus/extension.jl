abstract type AbstractMetaNexus{T} <: AbstractNexus{T} end
const PropDict = Dict{Symbol,Any}

function show(io::IO, g::AbstractMetaNexus{T}) where {T}
    dir = is_directed(g) ? "directed" : "undireced"
    print(io, "{$(nn(g)),$(na(g))} $dir $T metagraph")
end

# FORWARD DARI INTERFACE
@forward AbstractMetaNexus.core eltype

@forward AbstractMetaNexus.core nn
@forward AbstractMetaNexus.core na
@forward AbstractMetaNexus.core fadj
@forward AbstractMetaNexus.core nodes

has_node(g::AbstractMetaNexus{T}, n::T) where {T} = has_node(g.core, n)
has_arc(g::AbstractMetaNexus{T}, u::T, v::T, key::Int) where {T} =
    has_arc(g.core, u, v, key)

# FORWARD DARI GRAPH & DIGRAPH
add_arc!(g::AbstractMetaNexus, x...) = add_arc!(g.core, x...)
rem_arc!(g::AbstractMetaNexus, x...) = rem_arc!(g.core, x...)

add_node!(g::AbstractMetaNexus, x...) = add_node!(g.core, x...)
rem_node!(g::AbstractMetaNexus, x...) = rem_node!(g.core, x...)

# FORWARD DARI ARC
arcs(g::AbstractMetaNexus, x...) = arcs(g.core, x...)

add_arc!(g::AbstractMetaNexus{T}, a::Arc{T}) where {T} = add_arc!(g.core, a)
rem_arc!(g::AbstractMetaNexus{T}, a::Arc{T}) where {T} = rem_arc!(g.core, a)

has_arc(g::AbstractMetaNexus{T}, a::Arc{T}) where {T} = has_arc(g.core, a)

# universal metanexus methods
"""
    props(g, n)
    props(g, a)
    props(g, s, t, key)

Return a dictionary of all metadata from node `n`, or arc `a`
(optionally referenced by source node `s` and target node `t`).
"""
props(g::AbstractMetaNexus{T}, n::T) where {T} = get(PropDict, g.nprops, n)
props(g::AbstractMetaNexus{T}, u::T, v::T, key::Int) where {T} = props(g, Arc(u, v, key))

"""
    get_prop(g, n, prop)
    get_prop(g, a, prop)
    get_prop(g, s, t, key, prop)

Return the property `prop` defined for node `n`, or arc `a`
(optionally referenced by source node `s` and target node `t`).
"""
get_prop(g::AbstractMetaNexus{T}, n::T, prop::Symbol) where {T} = props(g, n)[prop]
get_prop(g::AbstractMetaNexus{T}, a::Arc{T}, prop::Symbol) where {T} = props(g, a)[prop]
get_prop(g::AbstractMetaNexus{T}, u::T, v::T, key::Int, prop::Symbol) where {T} =
    props(g, Arc(u, v, key))[prop]

"""
    has_prop(g, n, prop)
    has_prop(g, a, prop)
    has_prop(g, s, t, key, prop)

Return true if the property `prop` is defined for node `n`, or
arc `a` (optionally referenced by source node `s` and target node `t`).
"""
has_prop(g::AbstractMetaNexus{T}, n::T, prop::Symbol) where {T} =
    haskey(props(g, n), prop)
has_prop(g::AbstractMetaNexus{T}, a::Arc{T}, prop::Symbol) where {T} =
    haskey(props(g, a), prop)
has_prop(g::AbstractMetaNexus{T}, u::T, v::T, key::Int, prop::Symbol) where {T} =
    haskey(props(g, Arc(u, v, key)), prop)

_hasdict(g::AbstractMetaNexus{T}, n::T) where {T} = haskey(g.nprops, n)
_hasdict(g::AbstractMetaNexus{T}, a::Arc{T}) where {T} = haskey(g.aprops, a)

"""
    set_props!(g, n, dict)
    set_props!(g, a, dict)
    set_props!(g, s, t, key, dict)

Bulk set (merge) properties contained in `dict` with node `n`, or
arc `a` (optionally referenced by source node `s` and target node `t`).
"""
function set_props!(g::AbstractMetaNexus{T}, n::T, d::Dict) where {T}
    if has_node(g, n)
        !_hasdict(g, n) ? g.nprops[n] = d : merge!(g.nprops[n], d)
        return true
    else
        return false
    end
end
# set_props! on arcs is dependent on directedness

set_prop!(g::AbstractMetaNexus{T}, n::T, prop::Symbol, val) where {T} =
    set_props!(g, n, Dict(prop => val))
set_prop!(g::AbstractMetaNexus{T}, a::Arc{T}, prop::Symbol, val) where {T} =
    set_props!(g, a, Dict(prop => val))
set_prop!(g::AbstractMetaNexus{T}, u::T, v::T, key::Int, prop::Symbol, val) where {T} =
    set_prop!(g, Arc(u, v, key), prop, val)

"""
    rem_prop!(g, n, prop)
    rem_prop!(g, a, prop)
    rem_prop!(g, s, t, prop)

Remove property `prop` from node `n`, or arc `a`
(optionally referenced by source node `s` and target node `t`).
"""
rem_prop!(g::AbstractMetaNexus{T}, n::T, prop::Symbol) where {T} =
    delete!(g.nprops[n], prop)
# rem_prop juga sama diatur di tiap2 graph digraph
rem_prop!(g::AbstractMetaNexus{T}, u::T, v::T, key::Int, prop::Symbol) where {T} =
    rem_prop!(g, Arc(u, v, key), prop)

clear_props!(g::AbstractMetaNexus{T}, n::T) where {T} =
    _hasdict(g, n) && delete!(g.nprops, n)
clear_props!(g::AbstractMetaNexus{T}, a::Arc{T}) where {T} =
    _hasdict(g, a) && delete!(g.aprops, a)
clear_props!(g::AbstractMetaNexus{T}, u::T, v::T, key::Int) where {T} =
    clear_props!(g, Arc(u, v, key))

filter_arcs(g::AbstractMetaNexus, fn::Function) =
    Iterators.filter(a -> fn(g, a), arcs(g))
filter_arcs(g::AbstractMetaNexus, prop::Symbol) =
    filter_arcs(g, (g, a) -> has_prop(g, a, prop))
filter_arcs(g::AbstractMetaNexus, prop::Symbol, val) =
    filter_arcs(g, (g, a) -> has_prop(g, a, prop) && get_prop(g, a, prop) == val)

filter_nodes(g::AbstractMetaNexus, fn::Function) =
    Iterators.filter(n -> fn(g, n), nodes(g))
filter_nodes(g::AbstractMetaNexus, prop::Symbol) =
    filter_nodes(g, (g, n) -> has_prop(g, n, prop))
filter_nodes(g::AbstractMetaNexus, prop::Symbol, val) =
    filter_nodes(g, (g, n) -> has_prop(g, n, prop) && get_prop(g, n, prop) == val)

# getindex
getindex(g::AbstractMetaNexus{T}, n::T) where {T} = props(g, n)
getindex(g::AbstractMetaNexus{T}, a::Arc{T}) where {T} = props(g, a)
getindex(g::AbstractMetaNexus{T}, u::T, v::T, key::Int) where {T} =
    getindex(g, Arc(u, v, key))