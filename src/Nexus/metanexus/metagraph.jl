struct MetaGraph{T} <: AbstractMetaNexus{T}
    core::Graph{T}
    nprop::Dict{T,PropDict}
    aprop::Dict{Arc{T},PropDict}
    gprop::PropDict
end