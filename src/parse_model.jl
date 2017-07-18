# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE.md

import Base: getindex, length

### Model definitions for ABAQUS data model

abstract type AbstractMaterial end
abstract type AbstractMaterialProperty end
abstract type AbstractProperty end
abstract type AbstractStep end
abstract type AbstractBoundaryCondition end
abstract type AbstractOutputRequest end

type Mesh
    nodes :: Dict{Int, Vector{Float64}}
    node_sets :: Dict{String, Vector{Integer}}
    elements :: Dict{Int, Vector{Int}}
    element_types :: Dict{Int, Symbol}
    element_sets :: Dict{String, Vector{Integer}}
    surface_sets :: Dict{String, Vector{Tuple{Int, Symbol}}}
    surface_types :: Dict{String, Symbol}
end

function Mesh(d::Dict{String, Dict})
    return Mesh(d["nodes"], d["node_sets"], d["elements"],
                d["element_types"], d["element_sets"],
                d["surface_sets"], d["surface_types"])
end

type Model
    path :: AbstractString
    name :: AbstractString
    mesh :: Mesh
    materials :: Dict{Symbol, AbstractMaterial}
    properties :: Vector{AbstractProperty}
    boundary_conditions :: Vector{AbstractBoundaryCondition}
    steps :: Vector{AbstractStep}
end

type SolidSection <: AbstractProperty
    element_set :: Symbol
    material_name :: Symbol
end

type Material <: AbstractMaterial
    name :: Symbol
    properties :: Vector{AbstractMaterialProperty}
end

type Elastic <: AbstractMaterialProperty
    E :: Float64
    nu :: Float64
end

type Step <: AbstractStep
    kind :: Nullable{Symbol} # STATIC, ...
    boundary_conditions :: Vector{AbstractBoundaryCondition}
    output_requests :: Vector{AbstractOutputRequest}
end

type BoundaryCondition <: AbstractBoundaryCondition
    kind :: Symbol # BOUNDARY, CLOAD, DLOAD, DSLOAD, ...
    data :: Vector
    options :: Dict
end

type OutputRequest <: AbstractOutputRequest
    kind :: Symbol # NODE, EL, SECTION, ...
    data :: Vector
    options :: Dict
    target :: Symbol # PRINT, FILE
end

### Utility functions to parse ABAQUS .inp file to data model

type Keyword
    name :: AbstractString
    options :: Vector{Union{AbstractString, Pair}}
end

type AbaqusReaderState
    section :: Nullable{Keyword}
    material :: Nullable{AbstractMaterial}
    property :: Nullable{AbstractProperty}
    step :: Nullable{AbstractStep}
    data :: Vector{AbstractString}
end

function get_data(state::AbaqusReaderState)
    data = []
    for row in state.data
        row = strip(row, [' ', ','])
        col = split(row, ',')
        col = map(parse, col)
        push!(data, col)
    end
    return data
end

function get_options(state::AbaqusReaderState)
    return Dict(get(state.section).options)
end

function get_option(state::AbaqusReaderState, what::AbstractString)
    return get_options(state)[what]
end

function length(state::AbaqusReaderState)
    return length(state.data)
end

function is_comment(line)
    return startswith(line, "**")
end

function is_keyword(line)
    return startswith(line, "*") && !is_comment(line)
end

function parse_keyword(line; uppercase_keyword=true)
    args = split(line, ",")
    args = map(strip, args)
    keyword_name = strip(args[1], '*')
    if uppercase_keyword
        keyword_name = uppercase(keyword_name)
    end
    keyword = Keyword(keyword_name, [])
    for option in args[2:end]
        pair = split(option, "=")
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

macro register_abaqus_keyword(keyword)
    underscored = Symbol(replace(keyword, " ", "_"))
    quote
        global is_abaqus_keyword_registered, $underscored
        $underscored = Type{Val{Symbol($keyword)}}
        is_abaqus_keyword_registered(::Type{Val{Symbol($keyword)}}) = true
    end
end

function is_abaqus_keyword_registered(s::AbstractString)
    return is_abaqus_keyword_registered(Val{Symbol(s)})
end

function is_abaqus_keyword_registered(others)
    return false
end

function is_new_section(line)
    is_keyword(line) || return false
    section = parse_keyword(line)
    is_abaqus_keyword_registered(section.name) || return false
    return true
end

function maybe_close_section!(model, state; verbose=true)
    isnull(state.section) && return
    section_name = get(state.section).name
    verbose && info("Close section: $section_name")
    args = Tuple{Model, AbaqusReaderState, Type{Val{Symbol(section_name)}}}
    if method_exists(close_section!, args)
        close_section!(model, state, Val{Symbol(section_name)})
    else
        verbose && warn("no close_section! found for $section_name")
    end
    state.section = nothing
end

function maybe_open_section!(model, state; verbose=true)
    section_name = get(state.section).name
    section_options = get(state.section).options
    verbose && info("New section: $section_name with options $section_options")
    args = Tuple{Model, AbaqusReaderState, Type{Val{Symbol(section_name)}}}
    if method_exists(open_section!, args)
        open_section!(model, state, Val{Symbol(section_name)})
    else
        verbose && warn("no open_section! found for $section_name")
    end
end

function new_section!(model, state, line::AbstractString; verbose=true)
    maybe_close_section!(model, state; verbose=verbose)
    state.data = []
    state.section = parse_keyword(line)
    maybe_open_section!(model, state; verbose=verbose)
end

# open_section! is called right after keyword is found
function open_section! end

# close_section! is called at the end or section or before new keyword
function close_section! end

function process_line!(model, state, line; verbose=false)
    if isnull(state.section)
        verbose && info("section = nothing! line = $line")
        return
    end
    if is_keyword(line)
        warn("missing keyword? line = $line")
        # close section, this is probably keyword and collecting data should stop.
        maybe_close_section!(model, state)
        return
    end
    push!(state.data, line)
end

function abaqus_read_model(fn::String)

    model_path = dirname(fn)
    model_name = first(splitext(basename(fn)))
    mesh = Mesh(open(parse_abaqus, fn))
    materials = Dict()
    model = Model(model_path, model_name, mesh, materials, [], [], [])

    state = AbaqusReaderState(nothing, nothing, nothing, nothing, [])

    fid = open(fn)
    for line in eachline(fid)
        line = strip(line)
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

# add here only keywords when planning to define open_section! and/or
# close_section!, i.e. actually parse keyword to model. little bit of
# magic is happening here, but after calling macro there is typealias
# defined i.e. typealias SOLID_SECTION Type{Val{Symbol("SOLID_SECTION")}}
# and also is_keyword_registered("SOLID SECTION") returns true after
# registration, also notice underscoring

@register_abaqus_keyword("SOLID SECTION")

@register_abaqus_keyword("MATERIAL")
@register_abaqus_keyword("ELASTIC")

@register_abaqus_keyword("STEP")
@register_abaqus_keyword("STATIC")
@register_abaqus_keyword("END STEP")

@register_abaqus_keyword("BOUNDARY")
@register_abaqus_keyword("CLOAD")
@register_abaqus_keyword("DLOAD")
@register_abaqus_keyword("DSLOAD")
const BOUNDARY_CONDITIONS = Union{BOUNDARY, CLOAD, DLOAD, DSLOAD}

@register_abaqus_keyword("NODE PRINT")
@register_abaqus_keyword("EL PRINT")
@register_abaqus_keyword("SECTION PRINT")
const OUTPUT_REQUESTS = Union{NODE_PRINT, EL_PRINT, SECTION_PRINT}

## Properties

function open_section!(model, state, ::SOLID_SECTION)
    element_set = get_option(state, "ELSET")
    material_name = get_option(state, "MATERIAL")
    property = SolidSection(element_set, material_name)
    state.property = property
    push!(model.properties, property)
end

function close_section!(model, state, ::SOLID_SECTION)
    state.property = nothing
end

## Materials

function open_section!(model, state, ::MATERIAL)
    material_name = Symbol(get_option(state, "NAME"))
    material = Material(material_name, [])
    state.material = material
    model.materials[material_name] = material
end

function close_section!(model, state, ::ELASTIC)
    # FIXME
    @assert length(state) == 1
    E, nu = first(get_data(state))
    material_property = Elastic(E, nu)
    material = get(state.material)
    push!(material.properties, material_property)
end

## Steps

function open_section!(model, state, ::STEP)
    step = Step(nothing, Vector(), Vector())
    state.step = step
    push!(model.steps, step)
end

function open_section!(model, state, ::STATIC)
    isnull(state.step) && error("*STATIC outside *STEP ?")
    get(state.step).kind = :STATIC
end

function open_section!(model, state, ::END_STEP)
    state.step = nothing
end

## Steps -- boundary conditions

function close_section!(model, state, ::BOUNDARY_CONDITIONS)
    kind = Symbol(get(state.section).name)
    data = get_data(state)
    options = get_options(state)
    bc = BoundaryCondition(kind, data, options)
    if isnull(state.step)
        push!(model.boundary_conditions, bc)
    else
        step = get(state.step)
        push!(step.boundary_conditions, bc)
    end
end

## Steps -- output requests

function close_section!(model, state, ::OUTPUT_REQUESTS)
    kind, target = map(parse, split(get(state.section).name, " "))
    data = get_data(state)
    options = get_options(state)
    request = OutputRequest(kind, data, options, target)
    step = get(state.step)
    push!(step.output_requests, request)
end
