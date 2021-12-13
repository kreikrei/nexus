struct locper
    loc::vault
    per::Int
end

Base.show(io::IO, lp::locper) = print(io,"⟦i=$(lp.loc),t=$(lp.per)⟧")

function demands(demandlist::DataFrame)
    D = Dict{locper, Int}()

    for i in 1:ncol(demandlist)
        for t in 1:nrow(demandlist)
            k = locper(names(demandlist)[i] |> vault, t-1) # start dr t = 0
            v = demandlist[t,i]
            D[k] = v
        end
    end

    return D
end

function generatedemands(d::Dict{locper,Int}, s::Int, N::Int)
    return [typeof(d)(k => v + rand(-s:s) for (k,v) in d) for _ in 1:N]
end