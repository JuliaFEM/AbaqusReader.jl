# AbaqusReader.jl

[![Build Status](https://travis-ci.org/JuliaFEM/AbaqusReader.jl.svg?branch=master)](https://travis-ci.org/JuliaFEM/AbaqusReader.jl)[![Coverage Status](https://coveralls.io/repos/github/JuliaFEM/AbaqusReader.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaFEM/AbaqusReader.jl?branch=master)[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliafem.github.io/AbaqusReader.jl/stable)[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliafem.github.io/AbaqusReader.jl/latest)

AbaqusReader.jl can be used to parse ABAQUS .inp file format. Two functions is exported:
`abaqus_read_mesh(filename::String)` can be used to parse mesh to simple Dict-based structure.
With function `abaqus_read_model(filename::String)` it's also possible to parse more information
from model, like boundary conditions and steps.

Reading mesh is made simple:
```
julia> using AbaqusReader
julia> filename = Pkg.dir("AbaqusReader", "test", "test_parse_mesh", "cube_tet4.inp")
julia> mesh = abaqus_read_mesh(filename)
Dict{String,Dict} with 7 entries:
  "nodes"         => Dict(7=>[0.0, 10.0, 10.0],4=>[10.0, 0.0, 0.0],9=>[10.0, 10…
  "element_sets"  => Dict("CUBE"=>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1…
  "element_types" => Dict{Integer,Symbol}(Pair{Integer,Symbol}(2, :Tet4),Pair{I…
  "elements"      => Dict{Integer,Array{Integer,1}}(Pair{Integer,Array{Integer,…
  "surface_sets"  => Dict("LOAD"=>Tuple{Int64,Symbol}[(16, :S1), (8, :S1)],"ORD…
  "surface_types" => Dict("LOAD"=>:ELEMENT,"ORDER"=>:ELEMENT)
  "node_sets"     => Dict("SYM23"=>[5, 6, 7, 8],"SYM12"=>[5, 6, 3, 4],"NALL"=>[…
```

Like said, `mesh` is a simple dictionary containing other dictionaries like
`elements`, `nodes`, `element_sets` and so on. This is a good  starting point to
construct own finite element implementations based on real models done using ABAQUS.

If boundary conditions are also requested, `abaqus_read_model` must be used:
```
julia> model = abaqus_read_model("abaqus_file.inp")
```

This returns `AbaqusReader.Model` instance.

## Supported elements

- C3D4
- C3D8
- C3D10
- C3D20
- C3D20E
- S3
- STRI65
- CPS4
- T2D2
- T3D2
