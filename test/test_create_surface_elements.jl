# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

using AbaqusReader: create_surface_element, create_surface_elements

@testset "create surface element from voluminal element surface" begin
    element = create_surface_element(:Tet4, :S1, [8, 9, 10, 2])
    @test element == (:Tri3, [8, 10, 9])
end

@testset "create surface elements from voluminal element surface" begin
    mesh = Dict(
        "elements" => Dict(16 => [8, 9, 10, 2]),
        "element_types" => Dict(16 => :Tet4),
        "surface_sets" => Dict("LOAD" => [(16, :S1)]))
    elements = create_surface_elements(mesh, "LOAD")
    @test elements[1] == (:Tri3, [8,10,9])
end

@testset "throw error if unknown element or side defined" begin
    @test_throws(Exception, create_surface_element(:Tet5, :S1, [8, 9, 10, 2]))
    @test_throws(Exception, create_surface_element(:Tet4, :S5, [8, 9, 10, 2]))
end
