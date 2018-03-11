# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using AbaqusReader
using Base.Test

@testset "AbaqusReader.jl" begin
    include("test_parse_mesh.jl")
    include("test_parse_model.jl")
    include("test_create_surface_elements.jl")
    include("test_parse_t2d2.jl")
    include("test_download.jl")
end
