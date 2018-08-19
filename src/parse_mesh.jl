# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

import Base.parse

# Define element type and number of nodes in element
element_has_nodes(::Type{Val{:C3D4}}) = 4
element_has_type( ::Type{Val{:C3D4}}) = :Tet4

element_has_nodes(::Type{Val{:C3D8}}) = 8
element_has_type( ::Type{Val{:C3D8}}) = :Hex8

element_has_nodes(::Type{Val{:C3D10}}) = 10
element_has_type(::Type{Val{:C3D10}}) = :Tet10

element_has_nodes(::Type{Val{:C3D20}}) = 20
element_has_type(::Type{Val{:C3D20}}) = :Hex20

element_has_nodes(::Type{Val{:C3D20E}}) = 20

element_has_nodes(::Type{Val{:S3}}) = 3
element_has_type( ::Type{Val{:S3}}) = :Tri3

element_has_nodes(::Type{Val{:STRI65}}) = 6
element_has_type(::Type{Val{:STRI65}}) = :Tri6

element_has_nodes(::Type{Val{:CPS4}}) = 4
element_has_type(::Type{Val{:CPS4}}) = :Quad4

element_has_nodes(::Type{Val{:T2D2}}) = 2
element_has_type(::Type{Val{:T2D2}}) = :Seg2

element_has_nodes(::Type{Val{:T3D2}}) = 2
element_has_type(::Type{Val{:T3D2}}) = :Seg2

element_has_nodes(::Type{Val{:B33}}) = 2
element_has_type(::Type{Val{:B33}}) = :Seg2

"""Checks for a comment or empty line

Function return true, if line starts with comment character "**"
or has length of 0
"""
function empty_or_comment_line(line::T) where T<:AbstractString
    startswith(line, "**") || (length(line) == 0)
end

"""Match words from both sides of '=' character
"""
function matchset(definition)
    regexp = r"([\w\_\-]+[ ]*=[ ]*[\w\_\-]+)"
    collect(m.match for m = eachmatch(regexp, definition))
end

"""Parse string to get set type and name
"""
function parse_definition(definition)
    set_defs = Dict()
    set_definition = matchset(definition)
    set_definition == nothing && return nothing
    for x in set_definition
        name, vals = map(strip, split(x, "="))
        set_defs[lowercase(name)] = vals
    end
    set_defs
end

"""Parse all the numbers from string
"""
function parse_numbers(line, type_)
    regexp = r"[0-9]+"
    matches = collect((m.match for m = eachmatch(regexp, line)))
    map(x-> Base.parse(type_, x), matches)
end

"""Add set to model, if set exists
"""
function add_set!(model, definition, model_key, abaqus_key, ids)
    has_set_def = parse_definition(definition)
    if haskey(has_set_def, "elset")
        set_name = has_set_def[abaqus_key]
        @info("Adding $abaqus_key: $set_name")
        model[model_key][set_name] = ids
    end
end

"""Parse nodes from the lines
"""
function parse_section(model, lines, ::Symbol, idx_start, idx_end, ::Type{Val{:NODE}})
    nnodes = 0
    ids = Integer[]
    definition = lines[idx_start]
    for line in lines[idx_start + 1: idx_end]
        if !(empty_or_comment_line(line))
            m = collect((m.match for m = eachmatch(r"[-0-9.eE+]+", line)))
            node_id = parse(Int, m[1])
            coords = parse.(Float64, m[2:end])
            model["nodes"][node_id] = coords
            push!(ids, node_id)
            nnodes += 1
        end
    end
    @info("$nnodes nodes found")
    add_set!(model, definition, "node_sets", "nset", ids)
end

"""Custon regex to find match from string. Index used if there are multiple matches
"""
function regex_match(regex_str, line, idx)
    return match(regex_str, line).captures[idx]
end

"""Custom list iterator

Simple iterator for comsuming element list. Depending
on the used element, connectivity nodes might be listed
in multiple lines, which is why iterator is used to handle
this problem.
"""
function consumeList(arr, start, stop)
    idx = start - 1
    function _it()
        idx += 1
        if idx > stop
            return nothing
        end
        arr[idx]
    end
    _it
end

"""Parse elements from input lines

Reads element ids and their connectivity nodes from input lines.
If elset definition exists, also adds the set to model.
"""
function parse_section(model, lines, ::Symbol, idx_start, idx_end, ::Type{Val{:ELEMENT}})
    ids = Integer[]
    definition = lines[idx_start]
    regexp = r"TYPE=([\w\-\_]+)"i
    m = match(regexp, definition)
    m == nothing && error("Could not match regexp $regexp to line $definition")
    element_type = m[1]
    eltype_sym = Symbol(element_type)
    eltype_nodes = element_has_nodes(Val{eltype_sym})
    element_type = element_has_type(Val{eltype_sym})
    @info("Parsing elements. Type: $(m[1]). Topology: $(element_type)")
    list_iterator = consumeList(lines, idx_start+1, idx_end)
    line = list_iterator()
    while line != nothing
        numbers = parse_numbers(line, Int)
        if !(empty_or_comment_line(line))
            id = numbers[1]
            push!(ids, id)
            connectivity = numbers[2:end]
            while length(connectivity) != eltype_nodes
                @assert length(connectivity) < eltype_nodes
                line = list_iterator()
                numbers = parse_numbers(line, Int)
                push!(connectivity, numbers...)
            end
            model["elements"][id] = connectivity
            model["element_types"][id] = element_type
        end
        line = list_iterator()
    end
    add_set!(model, definition, "element_sets", "elset", ids)
end

"""Parse node and elementset from input lines
"""
function parse_section(model, lines, key, idx_start, idx_end, ::Union{Type{Val{:NSET}},
        Type{Val{:ELSET}}})
    data = Integer[]
    set_regex_string = Dict(:NSET  => r"NSET=([\w\-\_]+)",
                            :ELSET => r"ELSET=([\w\-\_]+)" )
    selected_set = key == :NSET ? "node_sets" : "element_sets"
    definition = lines[idx_start]
    regex_string = set_regex_string[key]
    set_name = regex_match(regex_string, definition, 1)
    @info("Creating $(lowercase(string(key))) $set_name")

    if endswith(strip(definition), "GENERATE")
        line = lines[idx_start + 1]
        first_id, last_id, step_ = parse_numbers(line, Int)
        set_ids = collect(first_id:step_:last_id)
        push!(data, set_ids...)
    else
        for line in lines[idx_start + 1: idx_end]
            if !(empty_or_comment_line(line))
                set_ids = parse_numbers(line, Int)
                push!(data, set_ids...)
            end
        end
    end
    model[selected_set][set_name] = data
end

"""Parse SURFACE keyword
"""
function parse_section(model, lines, ::Symbol, idx_start, idx_end, ::Type{Val{:SURFACE}})
    data = Vector{Tuple{Int64, Symbol}}()
    definition = lines[idx_start]

    has_set_def = parse_definition(definition)
    has_set_def != nothing || return
    set_type = get(has_set_def, "type", "UNKNOWN")
    set_name = has_set_def["name"]

    for line in lines[idx_start + 1: idx_end]
        empty_or_comment_line(line) && continue
        m = match(r"(?P<element_id>\d+),.*(?P<element_side>S\d+).*", line)
        element_id = parse(Int, m[:element_id])
        element_side = Symbol(m[:element_side])
        push!(data, (element_id, element_side))
    end
    model["surface_types"][set_name] = Symbol(set_type)
    model["surface_sets"][set_name] = data
    return
end

"""Find lines, which contain keywords, for example "*NODE"
"""
function find_keywords(lines)
    indexes = Integer[]
    for (idx, line) in enumerate(lines)
        if startswith(line, "*") && !startswith(line, "**")
            push!(indexes, idx)
        end
    end
    return indexes
end

"""Main function for parsing Abaqus input file.

Function parses Abaqus input file and generates a dictionary of
all the available keywords.
"""
function parse_abaqus(fid::IOStream)
    model = Dict{String, Dict}()
    model["nodes"] = Dict{Int64, Vector{Float64}}()
    model["node_sets"] = Dict{String, Vector{Int64}}()
    model["elements"] = Dict{Integer, Vector{Integer}}()
    model["element_types"] = Dict{Integer, Symbol}()
    model["element_sets"] = Dict{String, Vector{Int64}}()
    model["surface_sets"] = Dict{String, Vector{Tuple{Int64, Symbol}}}()
    model["surface_types"] = Dict{String, Symbol}()
    keyword_sym::Symbol = :none

    lines = readlines(fid)
    keyword_indexes = find_keywords(lines)
    nkeyword_indexes = length(keyword_indexes)
    push!(keyword_indexes, length(lines)+1)
    idx_start = keyword_indexes[1]

    for idx_end in keyword_indexes[2:end]
        keyword_line = strip(uppercase(lines[idx_start]))
        keyword = strip(regex_match(r"\s*([\w ]+)", keyword_line, 1))
        k_sym = Symbol(keyword)
        args = Tuple{Dict, Vector{Int}, Symbol, Int, Int, Type{Val{k_sym}}}
        if hasmethod(parse_section, args)
            parse_section(model, lines, k_sym, idx_start, idx_end-1, Val{k_sym})
        else
            @warn("Unknown section: '$(keyword)'")
        end
        idx_start = idx_end
    end
    return model
end

"""
    abaqus_read_mesh(fn::String)

Read ABAQUS mesh from file `fn`. Returns a dict with elements, nodes,
element sets, node sets and other topologically imporant things, but
not the actual model with boundary conditions, load steps and so on.
"""
function abaqus_read_mesh(fn::String)
    return open(parse_abaqus, fn)
end
