# This file is a part of project JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using Documenter
using AbaqusReader

deploydocs(
    deps = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/JuliaFEM/AbaqusReader.jl.git")
