struct MetaDigraph{T} <: AbstractMetaNexus{T}
    core::Digraph{T}
    nprop::Dict{T,PropDict}
    aprop::Dict{Arc{T},PropDict}
    gprop::PropDict
end



