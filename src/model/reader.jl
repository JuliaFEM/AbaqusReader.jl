# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

"""
    abaqus_read_model(fn::String) -> Model

Read complete ABAQUS model including mesh, materials, boundary conditions, and analysis steps.

This function performs **complete model parsing**, extracting the entire simulation definition
from an ABAQUS input file. Use this when you need to reproduce or analyze the full simulation setup,
not just the mesh geometry.

# Arguments
- `fn::String`: Path to the ABAQUS input file (`.inp`)

# Returns
An `AbaqusReader.Model` object with fields:
- `path::String`: Directory containing the input file
- `name::String`: Model name (basename without extension)
- `mesh::Mesh`: Mesh object containing all geometric data
  - `mesh.nodes`: Node coordinates
  - `mesh.elements`: Element connectivity
  - `mesh.element_types`: Element type mapping
  - `mesh.node_sets`: Named node sets
  - `mesh.element_sets`: Named element sets
  - `mesh.surface_sets`: Surface definitions
- `materials::Dict`: Material definitions with properties
  - Each material may contain elastic, density, plastic, etc.
- `properties::Vector`: Section property assignments (linking materials to element sets)
- `boundary_conditions::Vector`: Prescribed displacements, constraints, etc.
- `steps::Vector`: Analysis steps with loads, BCs, and output requests

# Examples
```julia
using AbaqusReader

# Read complete model
model = abaqus_read_model("simulation.inp")

# Access mesh (same structure as abaqus_read_mesh)
nodes = model.mesh.nodes
elements = model.mesh.elements

# Access material properties
for (name, material) in model.materials
    println("Material: \$name")
    for prop in material.properties
        if prop isa AbaqusReader.Elastic
            println("  E = \$(prop.E), ν = \$(prop.nu)")
        end
    end
end

# Iterate through boundary conditions
for bc in model.boundary_conditions
    println("BC type: \$(bc.kind), data: \$(bc.data)")
end

# Iterate through analysis steps
for step in model.steps
    println("Step type: \$(step.kind)")
    println("  BCs: \$(length(step.boundary_conditions))")
    println("  Outputs: \$(length(step.output_requests))")
end
```

# See Also
- [`abaqus_read_mesh`](@ref): Read only mesh geometry (faster, simpler output)
- [`create_surface_elements`](@ref): Extract surface elements from model

# Notes
- Slower than `abaqus_read_mesh` as it parses the entire model
- Returns structured `Model` object (not a simple Dict)
- Parses most common ABAQUS keywords but not every possible option
- Best suited for "flat" input files; structured part/assembly files may have limited support
- Use when you need materials, BCs, loads, or analysis parameters
"""
function abaqus_read_model(fn::String)
    model_path = dirname(fn)
    model_name = first(splitext(basename(fn)))

    # First parse mesh using mesh parser
    mesh_dict = open(fn) do fid
        parse_abaqus(fid, false)
    end
    mesh = Mesh(mesh_dict)

    # Initialize model
    materials = Dict()
    model = Model(model_path, model_name, nothing, mesh, materials, [], [], [])

    # Initialize parser state
    state = AbaqusReaderState(nothing, nothing, nothing, nothing, [])

    # Parse model-specific keywords
    fid = open(fn)
    for line in eachline(fid)
        line = convert(String, strip(line))
        is_comment(line) && continue
        if is_new_section(line)
            new_section!(model, state, line)
        else
            process_line!(model, state, line)
        end
    end
    close(fid)
    maybe_close_section!(model, state)

    # Validate model has minimum required content
    if isempty(model.mesh.nodes)
        error("Model has no nodes defined. Cannot continue with empty mesh.")
    end

    if isempty(model.mesh.elements)
        error("Model has no elements defined. Cannot continue with empty mesh.")
    end

    if isempty(model.materials) && !isempty(model.properties)
        @warn "Model has section properties but no materials defined. This may indicate parsing issues."
    end

    return model
end
