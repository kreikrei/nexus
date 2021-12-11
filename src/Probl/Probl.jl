# defines problem structures and its conversion process from raw data
using CSV
using DataFrames
using Distances

include("$(pwd())/src/Nexus/Nexus.jl")
include("forwarding.jl")
include("basenet.jl")
include("io.jl")

struct locper
    loc::vault
    per::Int
end

Base.show(io::IO, lp::locper) = print(io,"⟦i=$(lp.loc),t=$(lp.per)⟧")

khazanah = readdata("/data/khazanah-master.csv")
trayek = readdata("/data/trayek-usulan-essence.csv")
moda = readdata("/data/moda-hasil-estim copy.csv")

basegraph = baseGraph(khazanah, trayek, moda)
basedigraph = baseDigraph(basegraph)