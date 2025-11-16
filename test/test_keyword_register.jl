# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using Test

@testset "keyword register" begin
    # Test using full module paths
    AbaqusReader.register_abaqus_keyword("HEI")
    @test AbaqusReader.is_abaqus_keyword_registered("HEI")
    @test !AbaqusReader.is_abaqus_keyword_registered("EI")

    # Test Val return type
    val_result = AbaqusReader.register_abaqus_keyword("TEST_KEYWORD")
    @test val_result == Val{:TEST_KEYWORD}
    @test AbaqusReader.is_abaqus_keyword_registered("TEST_KEYWORD")
end
