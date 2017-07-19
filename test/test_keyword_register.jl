# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/JuliaFEM.jl/blob/master/LICENSE.md

using Base.Test

using AbaqusReader: register_abaqus_keyword, is_abaqus_keyword_registered

@testset "keyword register" begin
    register_abaqus_keyword("HEI")
    @test is_abaqus_keyword_registered("HEI")
    @test !is_abaqus_keyword_registered("EI")
end
