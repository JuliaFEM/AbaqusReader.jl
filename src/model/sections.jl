# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

"""
    maybe_close_section!(model, state)

Close current section and process accumulated data.

Dispatches to specific close handlers based on section name.
"""
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

"""
    maybe_open_section!(model, state)

Open new section and initialize state.

Dispatches to specific open handlers based on section name.
"""
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

"""
    new_section!(model, state, line::String)

Start a new keyword section.

Closes previous section, parses new keyword, and opens new section.
"""
function new_section!(model, state, line::String)
    maybe_close_section!(model, state)
    state.data = []
    state.section = parse_keyword(line)
    maybe_open_section!(model, state)
end

"""
    process_line!(model, state, line::String)

Process a data line within current section.

Accumulates data lines or closes section if new keyword detected.
"""
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

# =============================================================================
# Section Handlers - Properties
# =============================================================================

"""
    open_solid_section!(model, state)

Open SOLID SECTION and create property linking element set to material.
"""
function open_solid_section!(model, state)
    element_set = Symbol(get_option(state, "ELSET"))
    material_name = Symbol(get_option(state, "MATERIAL"))
    property = SolidSection(element_set, material_name)
    state.property = property
    push!(model.properties, property)
end

"""
    close_solid_section!(model, state)

Close SOLID SECTION (no data to process).
"""
function close_solid_section!(model, state)
    state.property = nothing
end

# =============================================================================
# Section Handlers - Materials
# =============================================================================

"""
    open_material!(model, state)

Open MATERIAL section and create new material.
"""
function open_material!(model, state)
    material_name = Symbol(get_option(state, "NAME"))
    material = Material(material_name, [])
    state.material = material
    model.materials[material_name] = material
end

"""
    close_elastic!(model, state)

Close ELASTIC section and add elastic properties to current material.
"""
function close_elastic!(model, state)
    @assert length(state) == 1
    E, nu = first(get_data(state))
    material_property = Elastic(E, nu)
    material = state.material
    @assert material !== nothing
    push!(material.properties, material_property)
end

# =============================================================================
# Section Handlers - Steps
# =============================================================================

"""
    open_step!(model, state)

Open STEP section and create new analysis step.
"""
function open_step!(model, state)
    step_ = Step(nothing, Vector(), Vector())
    state.step = step_
    push!(model.steps, step_)
end

"""
    open_static!(model, state)

Mark current step as STATIC analysis.
"""
function open_static!(model, state)
    state.step === nothing && error("*STATIC outside *STEP ?")
    state.step.kind = :STATIC
end

"""
    open_end_step!(model, state)

Close current step (END STEP keyword).
"""
function open_end_step!(model, state)
    state.step = nothing
end

# =============================================================================
# Section Handlers - Boundary Conditions
# =============================================================================

"""
    close_boundary_condition!(model, state)

Close boundary condition section (BOUNDARY, CLOAD, DLOAD, DSLOAD).

Adds BC to either global model or current step depending on context.
"""
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

# =============================================================================
# Section Handlers - Output Requests
# =============================================================================

"""
    close_output_request!(model, state)

Close output request section (NODE PRINT, EL PRINT, NODE FILE, EL FILE).

Adds output request to current step.
"""
function close_output_request!(model, state)
    kind, target = map(Meta.parse, split(state.section.name, " "))
    data = get_data(state)
    options = get_options(state)
    request = OutputRequest(Symbol(kind), data, options, Symbol(target))
    @assert state.step !== nothing
    push!(state.step.output_requests, request)
end
