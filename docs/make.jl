push!(LOAD_PATH,"../src/")
using Documenter, JSONTools

makedocs(
    sitename="JSONTools.jl Documentation",
    modules=[JSONTools],
)