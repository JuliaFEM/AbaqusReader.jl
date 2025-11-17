
module AbaqusReaderAPI

using HTTP
using JSON3
using AbaqusReader
import AbaqusReader: abaqus_parse_mesh, abaqus_parse_model

# CORS headers for cross-origin requests
const CORS_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
    "Access-Control-Allow-Headers" => "Content-Type",
    "Content-Type" => "application/json"
]

"""
Convert mesh dictionary to JSON-serializable format for Three.js
"""
function mesh_to_json(mesh::Dict)
    result = Dict{String,Any}()

    # Convert nodes to array format [[x,y,z], ...]
    nodes = []
    node_ids = sort(collect(keys(mesh["nodes"])))
    node_map = Dict(id => idx - 1 for (idx, id) in enumerate(node_ids))  # 0-based for JS

    for node_id in node_ids
        coords = mesh["nodes"][node_id]
        push!(nodes, coords)
    end
    result["nodes"] = nodes

    # Convert elements to connectivity arrays
    elements = []
    element_types = []
    element_ids = sort(collect(keys(mesh["elements"])))

    for elem_id in element_ids
        connectivity = mesh["elements"][elem_id]
        # Map node IDs to 0-based indices
        mapped_connectivity = [node_map[nid] for nid in connectivity]
        push!(elements, mapped_connectivity)
        push!(element_types, String(mesh["element_types"][elem_id]))
    end
    result["elements"] = elements
    result["element_types"] = element_types

    # Add sets information
    result["element_sets"] = Dict(k => v for (k, v) in mesh["element_sets"])
    result["node_sets"] = Dict(k => v for (k, v) in mesh["node_sets"])

    # Statistics
    result["stats"] = Dict(
        "num_nodes" => length(nodes),
        "num_elements" => length(elements),
        "num_element_sets" => length(mesh["element_sets"]),
        "num_node_sets" => length(mesh["node_sets"])
    )

    # If PART/ASSEMBLY format, include parts info
    if haskey(mesh, "parts")
        result["has_parts"] = true
        result["part_names"] = collect(keys(mesh["parts"]))
    else
        result["has_parts"] = false
    end

    return result
end

"""
Convert model to JSON-serializable format
"""
function model_to_json(model)
    result = Dict{String,Any}()

    # Basic info
    result["type"] = "model"

    # Materials
    materials = []
    for (name, mat) in model.materials
        mat_dict = Dict(
            "name" => name,
            "type" => String(mat.material_type)
        )
        push!(materials, mat_dict)
    end
    result["materials"] = materials

    # Properties
    properties = []
    for (name, prop) in model.properties
        prop_dict = Dict("name" => name)
        if !isnothing(prop.element_set)
            prop_dict["element_set"] = prop.element_set
        end
        if !isnothing(prop.material)
            prop_dict["material"] = prop.material
        end
        push!(properties, prop_dict)
    end
    result["properties"] = properties

    # Steps
    steps = []
    for step in model.steps
        step_dict = Dict(
            "name" => step.step_name,
            "type" => String(step.analysis_type)
        )
        push!(steps, step_dict)
    end
    result["steps"] = steps

    result["stats"] = Dict(
        "num_materials" => length(materials),
        "num_properties" => length(properties),
        "num_steps" => length(steps)
    )

    return result
end

"""
Parse ABAQUS input file and return mesh/model data
"""
function parse_handler(req::HTTP.Request)
    try
        # Get file content from request body
        content = String(req.body)

        if isempty(content)
            return HTTP.Response(400, CORS_HEADERS,
                JSON3.write(Dict("error" => "No file content provided")))
        end

        # Parse as mesh first (use imported function to avoid module-binding issues)
        mesh = abaqus_parse_mesh(content, verbose=false)
        result = mesh_to_json(mesh)
        result["success"] = true
        result["parse_type"] = "mesh"

        # Try to parse as complete model for additional info
        try
            model = abaqus_parse_model(content)
            result["model"] = model_to_json(model)
            result["parse_type"] = "full"
        catch e
            # Mesh-only parsing succeeded, that's fine
            @info "Full model parsing not available (mesh-only mode)"
        end

        return HTTP.Response(200, CORS_HEADERS, JSON3.write(result))

    catch e
        error_msg = sprint(showerror, e, catch_backtrace())
        @error "Parsing failed" exception = e

        result = Dict(
            "success" => false,
            "error" => string(e),
            "error_details" => error_msg,
            "suggestion" => "This file format might not be supported yet. Please report this issue with your .inp file attached."
        )

        return HTTP.Response(400, CORS_HEADERS, JSON3.write(result))
    end
end

"""
Health check endpoint
"""
function health_handler(req::HTTP.Request)
    result = Dict(
        "status" => "healthy",
        "service" => "AbaqusReader API",
        "version" => "0.1.0"
    )
    return HTTP.Response(200, CORS_HEADERS, JSON3.write(result))
end

"""
List available test files from testdata directory
"""
function list_testdata_handler(req::HTTP.Request)
    try
        # Get testdata directory path (relative to project root)
        testdata_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "testdata")

        files = []

        if isdir(testdata_dir)
            for file in readdir(testdata_dir)
                if endswith(file, ".inp")
                    filepath = joinpath(testdata_dir, file)
                    filesize = stat(filepath).size

                    # Format size nicely
                    size_str = if filesize < 1024
                        "$(filesize) B"
                    elseif filesize < 1024 * 1024
                        "$(round(filesize / 1024, digits=1)) KB"
                    else
                        "$(round(filesize / (1024 * 1024), digits=1)) MB"
                    end

                    push!(files, Dict(
                        "name" => file,
                        "size" => filesize,
                        "size_formatted" => size_str
                    ))
                end
            end
        end

        # Sort by size
        sort!(files, by=f -> f["size"])

        result = Dict(
            "success" => true,
            "files" => files,
            "count" => length(files)
        )

        return HTTP.Response(200, CORS_HEADERS, JSON3.write(result))

    catch e
        @error "Failed to list testdata files" exception = e
        result = Dict(
            "success" => false,
            "error" => string(e),
            "files" => []
        )
        return HTTP.Response(500, CORS_HEADERS, JSON3.write(result))
    end
end

"""
Load a test file from testdata directory
"""
function load_testdata_handler(req::HTTP.Request)
    try
        # Parse query parameters
        uri = HTTP.URI(req.target)
        params = HTTP.queryparams(uri)

        if !haskey(params, "file")
            return HTTP.Response(400, CORS_HEADERS,
                JSON3.write(Dict("error" => "Missing 'file' parameter")))
        end

        filename = params["file"]

        # Security: only allow .inp files and no path traversal
        if !endswith(filename, ".inp") || contains(filename, "..")
            return HTTP.Response(400, CORS_HEADERS,
                JSON3.write(Dict("error" => "Invalid filename")))
        end

        # Get testdata directory path
        testdata_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "testdata")
        filepath = joinpath(testdata_dir, filename)

        if !isfile(filepath)
            return HTTP.Response(404, CORS_HEADERS,
                JSON3.write(Dict("error" => "File not found")))
        end

        # Read and parse the file
        content = read(filepath, String)

        # Parse as mesh
        mesh = abaqus_parse_mesh(content, verbose=false)
        result = mesh_to_json(mesh)
        result["success"] = true
        result["parse_type"] = "mesh"
        result["filename"] = filename

        # Try to parse as complete model for additional info
        try
            model = abaqus_parse_model(content)
            result["model"] = model_to_json(model)
            result["parse_type"] = "full"
        catch e
            @info "Full model parsing not available for $filename (mesh-only mode)"
        end

        return HTTP.Response(200, CORS_HEADERS, JSON3.write(result))

    catch e
        error_msg = sprint(showerror, e, catch_backtrace())
        @error "Failed to load testdata file" exception = e

        result = Dict(
            "success" => false,
            "error" => string(e),
            "error_details" => error_msg
        )

        return HTTP.Response(500, CORS_HEADERS, JSON3.write(result))
    end
end

"""
Handle CORS preflight requests
"""
function cors_handler(req::HTTP.Request)
    return HTTP.Response(200, CORS_HEADERS, "")
end

# Router
function router(req::HTTP.Request)
    @info "$(req.method) $(req.target)"

    # Handle CORS preflight
    if req.method == "OPTIONS"
        return cors_handler(req)
    end

    # Route requests
    if req.method == "GET" && req.target == "/health"
        return health_handler(req)
    elseif req.method == "GET" && startswith(req.target, "/testdata/list")
        return list_testdata_handler(req)
    elseif req.method == "GET" && startswith(req.target, "/testdata/load")
        return load_testdata_handler(req)
    elseif req.method == "POST" && req.target == "/parse"
        return parse_handler(req)
    else
        return HTTP.Response(404, CORS_HEADERS,
            JSON3.write(Dict("error" => "Not found")))
    end
end

"""
Start the AbaqusReader API server
"""
function start(; host::AbstractString=get(ENV, "HOST", "0.0.0.0"), port::Integer=parse(Int, get(ENV, "PORT", "8080")))
    @info "Starting AbaqusReader API server on $host:$port"
    HTTP.serve(router, host, port)
end

end # module AbaqusReaderAPI
