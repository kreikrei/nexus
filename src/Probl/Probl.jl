# defines problem structures and its conversion process from raw data
using CSV
using DataFrames
using Distances

include("$(pwd())/src/Nexus/Nexus.jl")
include("forwarding.jl")
include("basenet.jl")
include("io.jl")

khazanah = readdata("/data/khazanah-master.csv")
trayek = readdata("/data/trayek-usulan-essence.csv")
moda = readdata("/data/moda-hasil-estim copy.csv")

basegraph = baseGraph(khazanah, trayek, moda)
basedigraph = baseDigraph(basegraph)

permintaan = readdata("/data/permintaan-recreated.csv")

# TODO #2 function to transform base network into expanded network
# TODO #3 function to build deterministic model from expanded network
# TODO #4 model to generate demand sample
# TODO #5 function to build stochastic model from expanded network