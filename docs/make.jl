# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using Documenter, AbaqusReader

# Copy visualizer to assets so Documenter includes it
visualizer_src = joinpath(@__DIR__, "src", "visualizer")
visualizer_assets = joinpath(@__DIR__, "src", "assets", "visualizer")
if isdir(visualizer_src) && !ispath(visualizer_assets)
  mkpath(dirname(visualizer_assets))
  cp(visualizer_src, visualizer_assets; force=true)
  @info "Copied visualizer to assets for Documenter"
end

makedocs(modules=[AbaqusReader],
  format=Documenter.HTML(
    prettyurls=get(ENV, "CI", "false") == "true",
    canonical="https://ahojukka5.github.io/AbaqusReader.jl",
    assets=String["assets/custom.css"],
    collapselevel=1,
    footer="AbaqusReader.jl - Modern FEM mesh parser for Julia",
    edit_link="master",
    ansicolor=true,
  ),
  checkdocs=:exports,
  sitename="AbaqusReader.jl",
  authors="Jukka Aho and contributors",
  pages=[
    "Home" => "index.md",
    "Philosophy" => "philosophy.md",
    "Lessons Learned" => "lessons_learned.md",
    "Examples" => "examples.md",
    "Supported Elements" => "elements.md",
    "Element Database" => "element_database.md",
    "API Reference" => "api.md",
    "Contributing" => "contributing.md",
  ]
)

deploydocs(
  repo="github.com/ahojukka5/AbaqusReader.jl.git",
  devbranch="master",
  push_preview=true,
)
