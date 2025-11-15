# ABAQUS Element Database

This TOML file defines the mapping from ABAQUS element types to generic element topology used by AbaqusReader.jl.

## File Format

Each element is defined as a TOML table with the following fields:

```toml
[ELEMENT_NAME]
nodes = <number of nodes>
type = "<generic element type>"
description = "<optional description>"
```

### Fields

- **`nodes`** (required): Integer specifying the number of nodes in the element
- **`type`** (required): String specifying the mesh topology type that this ABAQUS element maps to
  - The type uses an abbreviated naming convention: **ShapePrefix + NodeCount**
  - `"Tet4"`, `"Tet10"` - Tetrahedron with 4 or 10 nodes
  - `"Hex8"`, `"Hex20"` - Hexahedron with 8 or 20 nodes  
  - `"Wedge6"`, `"Wedge15"` - Wedge (pentahedron) with 6 or 15 nodes
  - `"Tri3"`, `"Tri6"` - Triangle with 3 or 6 nodes
  - `"Quad4"`, `"Quad8"` - Quadrilateral with 4 or 8 nodes
  - `"Seg2"`, `"Seg3"` - Segment (line) with 2 or 3 nodes
  - `"Poi1"` - Point (single node)
  - The number suffix makes it explicit how many nodes the element has
- **`description`** (optional): String describing the element (useful for documentation)

## Adding New Elements

To add support for a new ABAQUS element type:

1. Find the ABAQUS element documentation to determine:
   - Element name (e.g., `C3D8R`)
   - Number of nodes (e.g., `8`)
   - Basic topology (tetrahedral, hexahedral, shell, etc.)

1. Add a new section to this file in the appropriate category:

```toml
[YOUR_ELEMENT]
nodes = X
type = "AppropriateType"
description = "Brief description"
```

1. No code changes needed! The element will be automatically available after restarting Julia.

## Element Categories

The file is organized into sections for easier maintenance:

- **3D Solid Elements**: Tetrahedral, Wedge/Prism, Hexahedral
- **Cohesive Elements**: Interface/cohesive zone elements
- **Shell Elements**: Triangular and Quadrilateral shells
- **2D Continuum**: Plane stress (CPS), Plane strain (CPE), Axisymmetric (CAX)
- **Beam and Truss**: Line elements

## Element Naming Conventions

ABAQUS uses suffixes to indicate element formulation details:

- **`R`** = Reduced integration
- **`H`** = Hybrid formulation
- **`I`** = Incompatible modes
- **`M`** = Modified formulation
- **`E`** = Enhanced strain

Since AbaqusReader focuses on mesh topology (geometry), elements with the same node count map to the same generic type. For example, `C3D8`, `C3D8R`, `C3D8H`, and `C3D8I` all map to `"Hex8"` since they're all 8-node hexahedra.

## Contributing

If you need support for an ABAQUS element that's not in this database:

1. Add it to this TOML file following the format above
2. Add a test in `test/test_parse_mesh.jl` to verify it works
3. Submit a pull request!

The TOML format makes it easy for the community to expand element support without touching any Julia code.
