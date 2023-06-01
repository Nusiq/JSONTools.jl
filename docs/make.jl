push!(LOAD_PATH,"../src/")
using Documenter, JSONTools

makedocs(
    sitename="JSONTools.jl Documentation",
    modules=[JSONTools],
)

deploydocs(
    repo="github.com/Nusiq/JSONTools.jl.git",
)
