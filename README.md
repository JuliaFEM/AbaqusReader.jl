# AbaqusReader.jl - parse ABAQUS mesh files to Julia

[![ci][ci-img]][ci-url]
[![codecov][coverage-img]][coverage-url]
[![docs-stable][docs-stable-img]][docs-stable-url]
[![docs-dev][docs-dev-img]][docs-dev-url]

AbaqusReader.jl can be used to parse ABAQUS .inp file format. Two functions is
exported: `abaqus_read_mesh(filename::String)` can be used to parse mesh to
simple Dict-based structure. With function `abaqus_read_model(filename::String)`
it's also possible to parse more information from model, like boundary
conditions and steps.

Reading mesh is made simple:

```julia
using AbaqusReader
abaqus_read_mesh("cube_tet4.inp")
```

```text
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
construct own finite element implementations based on real models done using
ABAQUS.

If boundary conditions are also requested, `abaqus_read_model` must be used:

```julia
model = abaqus_read_model("abaqus_file.inp")
```

This returns `AbaqusReader.Model` instance.

## Supported elements
The following abaqus elements are supported, along with the corresponding number of nodes and the `elemen_types` key

|abaqus element| number of nodes| element_types|
|---------|:--:|---------|
| C3D4    | 4  |`:Tet4`  | 
| C3D4H   | 4  |`:Tet4`  | 
| C3D6    | 6  |`:Wedge6`| 
| C3D8    | 8  |`:Hex8`  |
| C3D10   | 10 |`:Tet10` |
| C3D20   | 20 |`:Hex20` |
| C3D20E  | 20 |`:Hex20` |
| S3      | 3  |`:Tri3`  |
| STRI65  | 6  |`:Tri6`  |
| CPS4    | 4  |`:Quad4` |
| T2D2    | 2  |`:Seg2`  |
| T3D2    | 2  |`:Seg2`  |
| B33     | 2  |`:Seg2`  |

adding new elments is very easy, just look at the first lines of `/src/parse_mesh.jl`

[ci-img]: https://github.com/JuliaFEM/AbaqusReader.jl/workflows/CI/badge.svg
[ci-url]: https://github.com/JuliaFEM/AbaqusReader.jl/actions?query=workflow%3ACI+branch%3Amaster

[coverage-img]: https://codecov.io/gh/JuliaFEM/AbaqusReader.jl/branch/master/graph/badge.svg?token=3aZGJjDsY9
[coverage-url]: https://codecov.io/gh/JuliaFEM/AbaqusReader.jl

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://juliafem.github.io/AbaqusReader.jl/stable

[docs-dev-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-dev-url]: https://juliafem.github.io/AbaqusReader.jl/latest

