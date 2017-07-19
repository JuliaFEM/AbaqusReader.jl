# This file is a part of project JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using Documenter
using AbaqusReader

makedocs(
    modules = [AbaqusReader],
    checkdocs = :all,
    strict = false)
