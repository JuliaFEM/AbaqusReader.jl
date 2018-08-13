# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using AbaqusReader
using Test

include("../docs/make.jl")

@testset "AbaqusReader.jl" begin
    @testset "test_parse_mesh" begin include("test_parse_mesh.jl") end
    @testset "test_parse_model" begin include("test_parse_model.jl") end
    @testset "test_create_surface_elements" begin include("test_create_surface_elements.jl") end
    @testset "test_download" begin include("test_download.jl") end
    @testset "test_parse_t2d2" begin include("test_parse_t2d2.jl") end
    @testset "test_parse_beams" begin include("test_parse_beams.jl") end
end

include("../docs/deploy.jl")
