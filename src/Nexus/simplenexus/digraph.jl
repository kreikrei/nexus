# Digraph
mutable struct Digraph{T} <: AbstractNexus{T}
    nn::Int
    na::Int
    fadj::Dict{T,Dict{T,Dict{Int,Nothing}}}
    badj::Dict{T,Dict{T,Dict{Int,Nothing}}}
end

eltype(::Digraph{T}) where T = T
is_directed(::Digraph{T}) where T = true
Digraph{T}() where T = begin
    fadj = Dict{T,Dict{T,Dict{Int,Nothing}}}()
    badj = Dict{T,Dict{T,Dict{Int,Nothing}}}()
    return Digraph(0, 0, fadj, badj)
end

badj(g::Digraph{T}) = g.badj

function add_arc!(G::Digraph{T}, u::T, v::T, key::Union{Int,Nothing}=nothing) where T
    haskey(G.fadj, u) || begin
       G.fadj[u] = Dict()
       G.badj[u] = Dict()
       G.nn += 1
    end
    haskey(G.badj, v) || begin
       G.badj[v] = Dict()
       G.fadj[v] = Dict()
       G.nn += 1
    end
    isnothing(key) && (key = new_arc_key(G, u, v))

    get!(G.fadj[u], v, Dict())
    get!(G.badj[v], u, Dict())

    haskey(G.fadj[u][v], key) || (G.na += 1)
    get!(G.fadj[u][v], key, nothing)
    get!(G.badj[v][u], key, nothing)
    return key
end

function new_arc_key(g::Digraph{T}, u::T, v::T) where T
    haskey(g.fadj[u], v) ? begin
        keylist = keys(g.fadj[u][v])
    end : return 1
    key = length(keylist)
    while key in keylist
        key += 1
    end # find lowest integer not used
    return key
end

function rem_arc!(G::Digraph{T}, u::T, v::T, key::Union{Int,Nothing}=nothing) where T
    haskey(G.fadj[u], v) ? d = G.fadj[u][v] : return false # no v on u
    isnothing(key) ? pop!(d) : haskey(d, key) ? delete!(d, key) : return false # rem key
    length(d) == 0 && begin
        delete!(G.fadj[u],v)
        delete!(G.badj[v],u)
    end
    G.na -= 1
    return true
end