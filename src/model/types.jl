# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

"""
Abstract types for the ABAQUS data model hierarchy.
"""
abstract type AbstractMaterial end
abstract type AbstractMaterialProperty end
abstract type AbstractProperty end
abstract type AbstractStep end
abstract type AbstractBoundaryCondition end
abstract type AbstractOutputRequest end

"""
    Mesh

Container for mesh geometry and topology.

# Fields
- `nodes::Dict{Int,Vector{Float64}}` - Node ID → coordinates
- `node_sets::Dict{String,Vector{Int}}` - Node set name → node IDs
- `elements::Dict{Int,Vector{Int}}` - Element ID → connectivity
- `element_types::Dict{Int,Symbol}` - Element ID → element type
- `element_sets::Dict{String,Vector{Int}}` - Element set name → element IDs
- `surface_sets::Dict{String,Vector{Tuple{Int,Symbol}}}` - Surface name → (element, face) pairs
- `surface_types::Dict{String,Symbol}` - Surface name → surface type
"""
mutable struct Mesh
    nodes::Dict{Int,Vector{Float64}}
    node_sets::Dict{String,Vector{Int}}
    elements::Dict{Int,Vector{Int}}
    element_types::Dict{Int,Symbol}
    element_sets::Dict{String,Vector{Int}}
    surface_sets::Dict{String,Vector{Tuple{Int,Symbol}}}
    surface_types::Dict{String,Symbol}
end

"""
    Mesh(d::Dict{String,Dict}) -> Mesh

Construct Mesh from dictionary (as returned by mesh parser).
"""
function Mesh(d::Dict{String,Dict})
    return Mesh(d["nodes"], d["node_sets"], d["elements"],
        d["element_types"], d["element_sets"],
        d["surface_sets"], d["surface_types"])
end

"""
    Model

Complete ABAQUS model including mesh, materials, properties, and analysis definition.

# Fields
- `path::String` - Path to input file
- `name::String` - Model name
- `mesh::Mesh` - Mesh geometry and topology
- `materials::Dict{Symbol,AbstractMaterial}` - Material definitions
- `properties::Vector{AbstractProperty}` - Section properties
- `boundary_conditions::Vector{AbstractBoundaryCondition}` - Global boundary conditions
- `steps::Vector{AbstractStep}` - Analysis steps
"""
mutable struct Model
    path::String
    name::String
    mesh::Mesh
    materials::Dict{Symbol,AbstractMaterial}
    properties::Vector{AbstractProperty}
    boundary_conditions::Vector{AbstractBoundaryCondition}
    steps::Vector{AbstractStep}
end

"""
    SolidSection <: AbstractProperty

Solid section property linking an element set to a material.

# Fields
- `element_set::Symbol` - Name of element set
- `material_name::Symbol` - Name of material
"""
mutable struct SolidSection <: AbstractProperty
    element_set::Symbol
    material_name::Symbol
end

"""
    Material <: AbstractMaterial

Material definition with properties.

# Fields
- `name::Symbol` - Material name
- `properties::Vector{AbstractMaterialProperty}` - Material properties (Elastic, etc.)
"""
mutable struct Material <: AbstractMaterial
    name::Symbol
    properties::Vector{AbstractMaterialProperty}
end

"""
    Elastic <: AbstractMaterialProperty

Linear elastic material property.

# Fields
- `E::Float64` - Young's modulus
- `nu::Float64` - Poisson's ratio
"""
mutable struct Elastic <: AbstractMaterialProperty
    E::Float64
    nu::Float64
end

"""
    Step <: AbstractStep

Analysis step definition.

# Fields
- `kind::Union{Symbol,Nothing}` - Step type (e.g., :STATIC)
- `boundary_conditions::Vector{AbstractBoundaryCondition}` - Step-specific BCs
- `output_requests::Vector{AbstractOutputRequest}` - Output requests for this step
"""
mutable struct Step <: AbstractStep
    kind::Union{Symbol,Nothing}
    boundary_conditions::Vector{AbstractBoundaryCondition}
    output_requests::Vector{AbstractOutputRequest}
end

"""
    BoundaryCondition <: AbstractBoundaryCondition

Boundary condition definition (loads, constraints, etc.).

# Fields
- `kind::Symbol` - BC type (e.g., :BOUNDARY, :CLOAD, :DLOAD, :DSLOAD)
- `data::Vector` - BC data rows
- `options::Dict` - BC options/parameters
"""
mutable struct BoundaryCondition <: AbstractBoundaryCondition
    kind::Symbol
    data::Vector
    options::Dict
end

"""
    OutputRequest <: AbstractOutputRequest

Output request for results writing.

# Fields
- `kind::Symbol` - Output type (e.g., :NODE, :EL, :SECTION)
- `data::Vector` - Output variable specifications
- `options::Dict` - Output options
- `target::Symbol` - Output target (:PRINT or :FILE)
"""
mutable struct OutputRequest <: AbstractOutputRequest
    kind::Symbol
    data::Vector
    options::Dict
    target::Symbol
end
