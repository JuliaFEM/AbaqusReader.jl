# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using Documenter, AbaqusReader

makedocs(modules=[AbaqusReader],
         format = :html,
         checkdocs = :all,
         sitename = "AbaqusReader.jl",
         pages = ["index.md"]
        )
