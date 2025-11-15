# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

"""
    abaqus_read_mesh(fn::String) -> Dict

Read ABAQUS `.inp` file and extract mesh geometry and topology.

This function performs **mesh-only parsing**, extracting nodes, elements, sets, and surfaces
without parsing materials, boundary conditions, or analysis steps. Use this when you only need
the geometric structure of the model.

# Arguments
- `fn::String`: Path to the ABAQUS input file (`.inp`)

# Returns
A `Dict{String, Any}` containing:
- `"nodes"`: `Dict{Int, Vector{Float64}}` - Node ID → coordinates [x, y, z]
- `"elements"`: `Dict{Int, Vector{Int}}` - Element ID → node connectivity
- `"element_types"`: `Dict{Int, Symbol}` - Element ID → topological type (e.g., `:Tet4`, `:Hex8`)
- `"element_codes"`: `Dict{Int, Symbol}` - Element ID → original ABAQUS element name (e.g., `:C3D8R`, `:CPS3`)
- `"node_sets"`: `Dict{String, Vector{Int}}` - Node set name → node IDs
- `"element_sets"`: `Dict{String, Vector{Int}}` - Element set name → element IDs
- `"surface_sets"`: `Dict{String, Vector{Tuple{Int, Symbol}}}` - Surface name → (element, face) pairs
- `"surface_types"`: `Dict{String, Symbol}` - Surface name → surface type (e.g., `:ELEMENT`)

# Examples
```julia
using AbaqusReader

# Read mesh from file
mesh = abaqus_read_mesh("model.inp")

# Access node coordinates
coords = mesh["nodes"][1]  # [x, y, z] for node 1

# Get element connectivity
elem_nodes = mesh["elements"][1]  # Node IDs for element 1

# Get topological element type
elem_type = mesh["element_types"][1]  # e.g., :Hex8

# Get original ABAQUS element code
elem_code = mesh["element_codes"][1]  # e.g., :C3D8R

# Get nodes in a set
boundary_nodes = mesh["node_sets"]["BOUNDARY"]
```

# See Also
- [`abaqus_read_model`](@ref): Read complete model including materials and boundary conditions
- [`create_surface_elements`](@ref): Extract surface elements from surface definitions

# Notes
- Supports 60+ ABAQUS element types (see documentation for full list)
- Returns simple dictionary structure for easy manipulation
- Much faster than `abaqus_read_model` when only mesh is needed
- Element types are mapped to generic topology (e.g., `C3D8R` → `:Hex8`)
- Original ABAQUS element names preserved in `element_codes` for traceability
"""
function abaqus_read_mesh(fn::String; kwargs...)
    verbose = get(kwargs, :verbose, true)
    return open(fn) do fid
        parse_abaqus(fid, verbose)
    end
end
