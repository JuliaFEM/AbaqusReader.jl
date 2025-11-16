# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

"""
    load_element_database()

Load element information from the TOML database file.

Returns a Dict mapping element symbols to tuples of (node_count, element_type).
"""
function load_element_database()
    toml_path = joinpath(@__DIR__, "..", "..", "data", "abaqus_elements.toml")
    element_data = TOML.parsefile(toml_path)

    # Convert to the format expected by the rest of the code
    element_info = Dict{Symbol,Tuple{Int,Symbol}}()
    for (elem_name, elem_props) in element_data
        elem_symbol = Symbol(elem_name)
        num_nodes = elem_props["nodes"]
        elem_type = Symbol(elem_props["type"])
        element_info[elem_symbol] = (num_nodes, elem_type)
    end

    return element_info
end

# Load element definitions at module initialization
const ELEMENT_INFO = load_element_database()

"""
    element_has_nodes(eltype::Symbol) -> Int

Get the number of nodes for a given element type.
"""
element_has_nodes(eltype::Symbol) = ELEMENT_INFO[eltype][1]

"""
    element_has_type(eltype::Symbol) -> Symbol

Get the mesh topology type for a given element type.
"""
element_has_type(eltype::Symbol) = ELEMENT_INFO[eltype][2]

# Legacy API for backward compatibility with tests
element_has_nodes(::Type{Val{T}}) where T = element_has_nodes(T)
element_has_type(::Type{Val{T}}) where T = element_has_type(T)
