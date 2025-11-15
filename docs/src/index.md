# AbaqusReader.jl

AbaqusReader.jl provides two distinct ways to read ABAQUS `.inp` files, depending on your needs.

**Design Philosophy**: We provide **topology** (geometry and connectivity), not **physics** (formulations and behavior). See our [Philosophy](philosophy.md) for why we separate these concerns.

## Two Approaches for Two Different Needs

### 1. Mesh-Only Parsing - `abaqus_read_mesh()`

When you only need the **geometry and topology** (nodes, elements, sets), use this function.
It returns a simple dictionary structure containing just the mesh data - perfect for:

- Visualizing geometry
- Converting meshes to other formats
- Quick mesh inspection
- Building your own FEM implementations on top of ABAQUS geometries

### 2. Complete Model Parsing - `abaqus_read_model()`

When you need to **reproduce the entire simulation**, use this function.
It parses the complete simulation recipe including mesh, materials, boundary conditions,
load steps, and analysis parameters - everything needed to:

- Fully understand the simulation setup
- Reproduce the analysis in another solver
- Extract complete simulation definitions programmatically
- Analyze or modify simulation parameters

## Important Notes

Both functions are primarily tested with "flat" input files (the original ABAQUS input file structure).
The more structured file format describing parts, assemblies, etc. may have limited support.

The `abaqus_read_model()` function parses many common ABAQUS features but does not cover every possible
keyword and option in the ABAQUS specification. It handles typical use cases for extracting complete
simulation definitions.
