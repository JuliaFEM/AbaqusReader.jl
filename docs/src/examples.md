# Examples

This page demonstrates the two main ways to use AbaqusReader.jl.

## Example 1: Reading Just the Mesh

The simplest use case - extract only geometry and topology for visualization or conversion:

```julia
using AbaqusReader

# Read mesh data from an ABAQUS input file
mesh = abaqus_read_mesh("my_model.inp")

# mesh is a Dict with the following keys:
# - "nodes": Dict mapping node IDs to coordinates [x, y, z]
# - "elements": Dict mapping element IDs to connectivity arrays
# - "element_types": Dict mapping element IDs to element type symbols
# - "node_sets": Dict mapping set names to arrays of node IDs
# - "element_sets": Dict mapping set names to arrays of element IDs
# - "surface_sets": Dict mapping surface names to arrays of (element_id, face_symbol) tuples
# - "surface_types": Dict mapping surface names to surface type (e.g., :ELEMENT)

# Access node coordinates
node_1_coords = mesh["nodes"][1]  # [x, y, z]

# Access all nodes in a node set
sym_nodes = mesh["node_sets"]["SYMMETRY"]

# Access elements in an element set
volume_elements = mesh["element_sets"]["PART1"]

# Get element connectivity
element_1_nodes = mesh["elements"][1]  # Array of node IDs

# Get element type
element_1_type = mesh["element_types"][1]  # e.g., :Tet4, :Hex8
```

### Use Cases for Mesh-Only Parsing

- **Mesh visualization**: Extract geometry for plotting with Makie.jl, Plots.jl, or external tools
- **Format conversion**: Convert ABAQUS meshes to other FEM formats
- **Custom FEM**: Build your own finite element implementation on ABAQUS geometries
- **Mesh inspection**: Quickly check mesh quality, element counts, node sets

## Example 2: Reading the Complete Model

When you need to reproduce the entire simulation, not just the geometry:

```julia
using AbaqusReader

# Read the complete model definition
model = abaqus_read_model("simulation.inp")

# model is an AbaqusReader.Model instance with fields:
# - mesh: Dict (same as returned by abaqus_read_mesh)
# - materials: Dict mapping material names to Material structs
# - properties: Dict of section properties
# - boundary_conditions: Array of BoundaryCondition structs
# - steps: Array of Step structs defining the analysis sequence

# Access the mesh (same as mesh-only parsing)
nodes = model.mesh["nodes"]
elements = model.mesh["elements"]

# Access material definitions
steel = model.materials["STEEL"]
# Materials contain properties like:
# - elastic: Young's modulus, Poisson's ratio
# - density: Material density
# - plastic: Yield stress, plastic strain curves

# Access boundary conditions
for bc in model.boundary_conditions
    println("BC on set: $(bc.set_name)")
    println("  DOF: $(bc.dof)")
    println("  Value: $(bc.value)")
end

# Access analysis steps
for step in model.steps
    println("Step: $(step.name)")
    println("  Type: $(step.type)")
    # Steps contain loads, BCs, and output requests specific to that step
end
```

### Use Cases for Complete Model Parsing

- **Simulation reproduction**: Extract all parameters to reproduce analysis in another solver
- **Model verification**: Programmatically check material properties, BCs, and loads
- **Parameter studies**: Extract and modify simulation parameters for batch studies
- **Documentation**: Auto-generate simulation documentation from .inp files
- **Solver development**: Use complete ABAQUS models as test cases for custom solvers

## Example 3: Extracting Surface Elements

Create explicit surface elements from volume element faces:

```julia
using AbaqusReader

# Read mesh
mesh = abaqus_read_mesh("model.inp")

# Create surface elements for a named surface
# This converts implicit surface definitions (element + face)
# into explicit surface element connectivity
surface_elements = create_surface_elements(mesh, "LOAD_SURFACE")

# Returns Dict with:
# - element IDs as keys
# - node connectivity arrays as values
# Surface elements are numbered starting from max(element_ids) + 1

# Example: Apply loads to surface nodes
surface_nodes = Set()
for (elem_id, connectivity) in surface_elements
    union!(surface_nodes, connectivity)
end
println("Surface has $(length(surface_nodes)) unique nodes")
```

## Example 4: Downloading Test Models

AbaqusReader includes a helper to download example ABAQUS models:

```julia
using AbaqusReader

# Download an example model (downloads to current directory)
filename = abaqus_download("piston_ring_2d")

# Then read it
mesh = abaqus_read_mesh(filename)
```

Available example models can be found in the AbaqusReader source repository.

## Working with Specific Element Types

The package automatically handles different ABAQUS element types:

```julia
mesh = abaqus_read_mesh("mixed_elements.inp")

# Find all tetrahedral elements
tet_elements = [id for (id, etype) in mesh["element_types"] if etype == :Tet4]

# Find all hexahedral elements  
hex_elements = [id for (id, etype) in mesh["element_types"] if etype == :Hex8]

# Get connectivity for specific element type
for elem_id in tet_elements
    nodes = mesh["elements"][elem_id]
    @assert length(nodes) == 4  # Tet4 has 4 nodes
end
```

## Tips and Best Practices

### Quiet Operation

By default, AbaqusReader operates quietly. If you need debug output for troubleshooting:

```julia
using Logging

with_logger(ConsoleLogger(stderr, Logging.Debug)) do
    mesh = abaqus_read_mesh("model.inp")
end
```

### Large Models

For large models, mesh-only parsing is significantly faster than complete model parsing:

```julia
# Fast - only parses mesh sections
@time mesh = abaqus_read_mesh("large_model.inp")

# Slower - parses everything
@time model = abaqus_read_model("large_model.inp")
```

Choose the appropriate function for your needs to optimize performance.

### Flat vs. Structured Input Files

The package works best with "flat" ABAQUS input files where all definitions are in a single file.
Structured files with multiple parts and assemblies may require consolidation first.
