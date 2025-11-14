# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

### Model definitions for ABAQUS data model

abstract type AbstractMaterial end
abstract type AbstractMaterialProperty end
abstract type AbstractProperty end
abstract type AbstractStep end
abstract type AbstractBoundaryCondition end
abstract type AbstractOutputRequest end

mutable struct Mesh
    nodes::Dict{Int,Vector{Float64}}
    node_sets::Dict{String,Vector{Int}}
    elements::Dict{Int,Vector{Int}}
    element_types::Dict{Int,Symbol}
    element_sets::Dict{String,Vector{Int}}
    surface_sets::Dict{String,Vector{Tuple{Int,Symbol}}}
    surface_types::Dict{String,Symbol}
end

function Mesh(d::Dict{String,Dict})
    return Mesh(d["nodes"], d["node_sets"], d["elements"],
        d["element_types"], d["element_sets"],
        d["surface_sets"], d["surface_types"])
end

mutable struct Model
    path::String
    name::String
    mesh::Mesh
    materials::Dict{Symbol,AbstractMaterial}
    properties::Vector{AbstractProperty}
    boundary_conditions::Vector{AbstractBoundaryCondition}
    steps::Vector{AbstractStep}
end

mutable struct SolidSection <: AbstractProperty
    element_set::Symbol
    material_name::Symbol
end

mutable struct Material <: AbstractMaterial
    name::Symbol
    properties::Vector{AbstractMaterialProperty}
end

mutable struct Elastic <: AbstractMaterialProperty
    E::Float64
    nu::Float64
end

mutable struct Step <: AbstractStep
    kind::Union{Symbol,Nothing} # STATIC, ...
    boundary_conditions::Vector{AbstractBoundaryCondition}
    output_requests::Vector{AbstractOutputRequest}
end

mutable struct BoundaryCondition <: AbstractBoundaryCondition
    kind::Symbol # BOUNDARY, CLOAD, DLOAD, DSLOAD, ...
    data::Vector
    options::Dict
end

mutable struct OutputRequest <: AbstractOutputRequest
    kind::Symbol # NODE, EL, SECTION, ...
    data::Vector
    options::Dict
    target::Symbol # PRINT, FILE
end

### Utility functions to parse ABAQUS .inp file to data model

mutable struct Keyword
    name::String
    options::Vector{Union{String,Pair}}
end

mutable struct AbaqusReaderState
    section::Union{Keyword,Nothing}
    material::Union{AbstractMaterial,Nothing}
    property::Union{AbstractProperty,Nothing}
    step::Union{AbstractStep,Nothing}
    data::Vector{String}
end

function get_data(state::AbaqusReaderState)
    data = []
    for row in state.data
        row = strip(row, [' ', ','])
        col = split(row, ',')
        col = map(Meta.parse, col)
        push!(data, col)
    end
    return data
end

function get_options(state::AbaqusReaderState)
    section = state.section
    section === nothing && return Dict()
    return Dict(section.options)
end

function get_option(state::AbaqusReaderState, what::String)
    return get_options(state)[what]
end

Base.length(state::AbaqusReaderState) = length(state.data)

is_comment(line::AbstractString) = startswith(line, "**")
is_keyword(line::AbstractString) = startswith(line, "*") && !is_comment(line)

function parse_keyword(line; uppercase_keyword=true)
    args = split(line, ",")
    args = map(String, map(strip, args))
    keyword_name = strip(args[1], '*')
    if uppercase_keyword
        keyword_name = uppercase(keyword_name)
    end
    keyword = Keyword(keyword_name, [])
    for option in args[2:end]
        pair = map(String, split(option, "="))
        if uppercase_keyword
            pair[1] = uppercase(pair[1])
        end
        if length(pair) == 1
            push!(keyword.options, pair[1])
        elseif length(pair) == 2
            push!(keyword.options, pair[1] => pair[2])
        else
            error("Keyword failure: $line, $option, $pair")
        end
    end
    return keyword
end

function is_new_section(line::AbstractString)
    is_keyword(line) || return false
    section = parse_keyword(line)
    return is_abaqus_keyword_registered(section.name)
end

# Simpler dispatch using direct function calls based on section name
function maybe_close_section!(model, state)
    state.section === nothing && return
    section_name = state.section.name
    @debug "Close section: $section_name"

    # Direct dispatch based on section name
    if section_name == "SOLID SECTION"
        close_solid_section!(model, state)
    elseif section_name == "ELASTIC"
        close_elastic!(model, state)
    elseif section_name in ("BOUNDARY", "CLOAD", "DLOAD", "DSLOAD")
        close_boundary_condition!(model, state)
    elseif section_name in ("NODE PRINT", "EL PRINT", "SECTION PRINT")
        close_output_request!(model, state)
    else
        @debug "No close handler for $section_name"
    end

    state.section = nothing
end

function maybe_open_section!(model, state)
    section_name = state.section.name
    section_options = state.section.options
    @debug "New section: $section_name with options $section_options"

    # Direct dispatch based on section name
    if section_name == "SOLID SECTION"
        open_solid_section!(model, state)
    elseif section_name == "MATERIAL"
        open_material!(model, state)
    elseif section_name == "STEP"
        open_step!(model, state)
    elseif section_name == "STATIC"
        open_static!(model, state)
    elseif section_name == "END STEP"
        open_end_step!(model, state)
    else
        @debug "No open handler for $section_name"
    end
end

function new_section!(model, state, line::String)
    maybe_close_section!(model, state)
    state.data = []
    state.section = parse_keyword(line)
    maybe_open_section!(model, state)
end

function process_line!(model, state, line::String)
    if state.section === nothing
        @debug "section = nothing! line = $line"
        return
    end
    if is_keyword(line)
        @warn("missing keyword? line = $line")
        # close section, this is probably keyword and collecting data should stop.
        maybe_close_section!(model, state)
        return
    end
    push!(state.data, line)
end

"""
    abaqus_read_model(filename::String)

Read ABAQUS model from file. Include also boundary conditions, load steps
and so on. If only mesh is needed, it's better to use `abaqus_read_mesh`
insted.
"""
function abaqus_read_model(fn::String)

    model_path = dirname(fn)
    model_name = first(splitext(basename(fn)))
    mesh_dict = open(fn) do fid
        parse_abaqus(fid, false)
    end
    mesh = Mesh(mesh_dict)
    materials = Dict()
    model = Model(model_path, model_name, mesh, materials, [], [], [])

    state = AbaqusReaderState(nothing, nothing, nothing, nothing, [])

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

    return model
end

### Code to parse ABAQUS .inp to data model

# Keywords we recognize and process
const RECOGNIZED_KEYWORDS = Set([
    "SOLID SECTION",
    "MATERIAL",
    "ELASTIC",
    "STEP",
    "STATIC",
    "END STEP",
    "BOUNDARY",
    "CLOAD",
    "DLOAD",
    "DSLOAD",
    "NODE PRINT",
    "EL PRINT",
    "SECTION PRINT"
])

function is_abaqus_keyword_registered(keyword::String)
    return keyword in RECOGNIZED_KEYWORDS
end

## Properties

function open_solid_section!(model, state)
    element_set = Symbol(get_option(state, "ELSET"))
    material_name = Symbol(get_option(state, "MATERIAL"))
    property = SolidSection(element_set, material_name)
    state.property = property
    push!(model.properties, property)
end

function close_solid_section!(model, state)
    state.property = nothing
end

## Materials

function open_material!(model, state)
    material_name = Symbol(get_option(state, "NAME"))
    material = Material(material_name, [])
    state.material = material
    model.materials[material_name] = material
end

function close_elastic!(model, state)
    @assert length(state) == 1
    E, nu = first(get_data(state))
    material_property = Elastic(E, nu)
    material = state.material
    @assert material !== nothing
    push!(material.properties, material_property)
end

## Steps

function open_step!(model, state)
    step_ = Step(nothing, Vector(), Vector())
    state.step = step_
    push!(model.steps, step_)
end

function open_static!(model, state)
    state.step === nothing && error("*STATIC outside *STEP ?")
    state.step.kind = :STATIC
end

function open_end_step!(model, state)
    state.step = nothing
end

## Steps -- boundary conditions

function close_boundary_condition!(model, state)
    kind = Symbol(state.section.name)
    data = get_data(state)
    options = get_options(state)
    bc = BoundaryCondition(kind, data, options)
    if state.step === nothing
        push!(model.boundary_conditions, bc)
    else
        push!(state.step.boundary_conditions, bc)
    end
end

## Steps -- output requests

function close_output_request!(model, state)
    kind, target = map(Meta.parse, split(state.section.name, " "))
    data = get_data(state)
    options = get_options(state)
    request = OutputRequest(Symbol(kind), data, options, Symbol(target))
    @assert state.step !== nothing
    push!(state.step.output_requests, request)
end
