# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using Logging

# Define element type and number of nodes - using simple Symbol dispatch
const ELEMENT_INFO = Dict{Symbol,Tuple{Int,Symbol}}(
    :C3D4 => (4, :Tet4),
    :C3D6 => (6, :Wedge6),
    :C3D4H => (4, :Tet4),
    :C3D8 => (8, :Hex8),
    :C3D8R => (8, :Hex8),
    :COH3D8 => (8, :Hex8),
    :C3D10 => (10, :Tet10),
    :C3D10H => (10, :Tet10),
    :C3D20 => (20, :Hex20),
    :C3D20E => (20, :Hex20),
    :S3 => (3, :Tri3),
    :CPS3 => (3, :CPS3),
    :STRI65 => (6, :Tri6),
    :CPS4 => (4, :Quad4),
    :CPS4R => (4, :Quad4),
    :T2D2 => (2, :Seg2),
    :T3D2 => (2, :Seg2),
    :B33 => (2, :Seg2)
)

element_has_nodes(eltype::Symbol) = ELEMENT_INFO[eltype][1]
element_has_type(eltype::Symbol) = ELEMENT_INFO[eltype][2]

# Legacy API for backward compatibility with tests
element_has_nodes(::Type{Val{T}}) where T = element_has_nodes(T)
element_has_type(::Type{Val{T}}) where T = element_has_type(T)

"""Checks for a comment or empty line

Returns true if line starts with comment character "**" or is empty
"""
empty_or_comment_line(line::AbstractString) = startswith(line, "**") || isempty(line)

"""Match words from both sides of '=' character
"""
function matchset(definition::AbstractString)
    regexp = r"([\w\_\-]+[ ]*=[ ]*[\w\_\-]+)"
    return [m.match for m in eachmatch(regexp, definition)]
end

"""Parse string to get set type and name
"""
function parse_definition(definition::AbstractString)
    set_defs = Dict{String,String}()
    set_definition = matchset(definition)
    isempty(set_definition) && return nothing
    for x in set_definition
        name, vals = map(strip, split(x, "="))
        set_defs[lowercase(name)] = vals
    end
    return set_defs
end

"""Parse all the numbers from string
"""
function parse_numbers(line, type_::Type{T})::Vector{T} where {T}
    regexp = r"[0-9]+"
    matches = (m.match for m in eachmatch(regexp, line))
    return map(x -> parse(type_, x), matches)
end

"""Add set to model, if set exists
"""
function add_set!(model, definition, model_key, abaqus_key, ids)
    has_set_def = parse_definition(definition)
    has_set_def === nothing && return
    if haskey(has_set_def, abaqus_key)
        set_name = has_set_def[abaqus_key]
        @debug "Adding $abaqus_key: $set_name"
        model[model_key][set_name] = ids
    end
end

"""Parse nodes from the lines
"""
function parse_section(model, lines, ::Symbol, idx_start, idx_end, ::Type{Val{:NODE}})
    nnodes = 0
    ids = Int[]
    definition = lines[idx_start]
    for line in lines[idx_start+1:idx_end]
        empty_or_comment_line(line) && continue
        m = [m.match for m in eachmatch(r"[-0-9.eE+]+", line)]
        node_id = parse(Int, m[1])
        coords = parse.(Float64, m[2:end])
        model["nodes"][node_id] = coords
        push!(ids, node_id)
        nnodes += 1
    end
    @debug "$nnodes nodes found"
    add_set!(model, definition, "node_sets", "nset", ids)
end

"""Custom regex to find match from string. Index used if there are multiple matches
"""
function regex_match(regex_str::Regex, line::AbstractString, idx::Int)
    m = match(regex_str, line)
    return m === nothing ? nothing : m.captures[idx]
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
    ids = Int[]
    definition = lines[idx_start]
    regexp = r"TYPE=([\w\-\_]+)"i
    m = match(regexp, definition)
    m === nothing && error("Could not match regexp $regexp to line $definition")
    element_type = uppercase(m[1])
    eltype_sym = Symbol(element_type)
    eltype_nodes = element_has_nodes(eltype_sym)
    element_type = element_has_type(eltype_sym)
    @debug "Parsing elements. Type: $(m[1]). Topology: $element_type"
    list_iterator = consumeList(lines, idx_start + 1, idx_end)
    line = list_iterator()
    while line !== nothing
        empty_or_comment_line(line) && (line = list_iterator(); continue)
        numbers = parse_numbers(line, Int)
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
        line = list_iterator()
    end
    add_set!(model, definition, "element_sets", "elset", ids)
end

"""Parse node and elementset from input lines
"""
function parse_section(model, lines, key, idx_start, idx_end, ::Union{Type{Val{:NSET}},Type{Val{:ELSET}}})
    data = Int[]
    set_regex_string = Dict(:NSET => r"((?<=NSET=)([\w\-\_]+)|(?<=NSET=\")([\w\-\_\ ]+)(?=\"))"i,
        :ELSET => r"((?<=ELSET=)([\w\-\_]+)|(?<=ELSET=\")([\w\-\_\ ]+)(?=\"))"i)
    selected_set = key == :NSET ? "node_sets" : "element_sets"
    definition = lines[idx_start]
    regex_string = set_regex_string[key]
    set_name = regex_match(regex_string, definition, 1)

    # If no set name found, error out
    set_name === nothing && error("Could not find set name in definition: $definition")

    @debug "Creating $(lowercase(string(key))) $set_name"

    if endswith(strip(uppercase(definition)), "GENERATE")
        line = lines[idx_start+1]
        first_id, last_id, step_ = parse_numbers(line, Int)
        set_ids = collect(first_id:step_:last_id)
        push!(data, set_ids...)
    else
        for line in lines[idx_start+1:idx_end]
            empty_or_comment_line(line) && continue
            set_ids = parse_numbers(line, Int)::Vector{Int}
            push!(data, set_ids...)
        end
    end
    model[selected_set][set_name] = data
end

"""Parse SURFACE keyword
"""
function parse_section(model, lines, ::Symbol, idx_start, idx_end, ::Type{Val{:SURFACE}})
    data = Vector{Tuple{Int,Symbol}}()
    definition = lines[idx_start]

    has_set_def = parse_definition(definition)
    has_set_def != nothing || return
    set_type = get(has_set_def, "type", "UNKNOWN")
    set_name = has_set_def["name"]

    for line in lines[idx_start+1:idx_end]
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

"""Find lines which contain keywords, for example "*NODE"
"""
function find_keywords(lines::Vector)
    indexes = Int[]
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
function parse_abaqus(fid::IOStream, verbose::Bool=true)
    model = Dict{String,Dict}()
    model["nodes"] = Dict{Int,Vector{Float64}}()
    model["node_sets"] = Dict{String,Vector{Int}}()
    model["elements"] = Dict{Int,Vector{Int}}()
    model["element_types"] = Dict{Int,Symbol}()
    model["element_sets"] = Dict{String,Vector{Int}}()
    model["surface_sets"] = Dict{String,Vector{Tuple{Int,Symbol}}}()
    model["surface_types"] = Dict{String,Symbol}()

    lines = readlines(fid)
    keyword_indexes = find_keywords(lines)
    push!(keyword_indexes, length(lines) + 1)
    idx_start = keyword_indexes[1]

    for idx_end in keyword_indexes[2:end]
        keyword_line = strip(uppercase(lines[idx_start]))
        keyword = strip(regex_match(r"\s*([\w ]+)", keyword_line, 1))
        k_sym = Symbol(keyword)

        # Dispatch based on keyword symbol
        try
            if k_sym == :NODE
                parse_section(model, lines, k_sym, idx_start, idx_end - 1, Val{:NODE})
            elseif k_sym == :ELEMENT
                parse_section(model, lines, k_sym, idx_start, idx_end - 1, Val{:ELEMENT})
            elseif k_sym == :NSET
                parse_section(model, lines, k_sym, idx_start, idx_end - 1, Val{:NSET})
            elseif k_sym == :ELSET
                parse_section(model, lines, k_sym, idx_start, idx_end - 1, Val{:ELSET})
            elseif k_sym == :SURFACE
                parse_section(model, lines, k_sym, idx_start, idx_end - 1, Val{:SURFACE})
            else
                verbose && @warn "Unknown section: '$(keyword)'"
            end
        catch e
            @error "Error parsing section $keyword" exception = e
            rethrow()
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
function abaqus_read_mesh(fn::String; kwargs...)
    verbose = get(kwargs, :verbose, true)
    return open(fn) do fid
        parse_abaqus(fid, verbose)
    end
end
