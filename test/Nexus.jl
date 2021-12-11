workdir = pwd()

refpath = "$workdir/src/Nexus"
push!(LOAD_PATH, refpath)

using Revise
using Nexus