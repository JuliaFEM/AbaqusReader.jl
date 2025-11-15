# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using Documenter, AbaqusReader

makedocs(modules=[AbaqusReader],
  format=Documenter.HTML(),
  checkdocs=:exports,
  sitename="AbaqusReader.jl",
  pages=[
    "Home" => "index.md",
    "Philosophy" => "philosophy.md",
    "Examples" => "examples.md",
    "Supported Elements" => "elements.md",
    "Element Database" => "element_database.md",
    "API Reference" => "api.md",
    "Contributing" => "contributing.md",
  ]
)
