using Test
using AbaqusReader

@testset "Real-world ABAQUS file parsing" begin

    testdir = joinpath(@__DIR__, "test_real_world")

    @testset "Shell box - mesh parsing" begin
        mesh = abaqus_read_mesh(joinpath(testdir, "shell_box.inp"))

        # Check nodes
        @test haskey(mesh, "nodes")
        @test length(mesh["nodes"]) == 8

        # Check S4 shell elements
        @test haskey(mesh, "elements")
        @test haskey(mesh["elements"], "S4")
        @test length(mesh["elements"]["S4"]) == 6

        # Check element sets
        @test haskey(mesh, "element_sets")
        @test haskey(mesh["element_sets"], "BOTTOM")
        @test haskey(mesh["element_sets"], "TOP")
        @test haskey(mesh["element_sets"], "EALL")

        # Check node sets
        @test haskey(mesh, "node_sets")
        @test haskey(mesh["node_sets"], "NLOWER")
        @test haskey(mesh["node_sets"], "NUPPER")
    end

    @testset "Shell box - model parsing" begin
        model = abaqus_read_model(joinpath(testdir, "shell_box.inp"))

        # Check material
        @test length(model.materials) == 1
        @test haskey(model.materials, :STEEL)
        mat = model.materials[:STEEL]
        @test mat.name == "STEEL"
        @test length(mat.properties) >= 3  # elastic, plastic, density

        # Check for elastic property
        elastic_idx = findfirst(p -> isa(p, AbaqusReader.Elastic), mat.properties)
        @test elastic_idx !== nothing

        # Check for plastic property
        plastic_idx = findfirst(p -> isa(p, AbaqusReader.Plastic), mat.properties)
        @test plastic_idx !== nothing
        if plastic_idx !== nothing
            plastic = mat.properties[plastic_idx]
            @test length(plastic.table) == 3
        end

        # Check for density
        density_idx = findfirst(p -> isa(p, AbaqusReader.Density), mat.properties)
        @test density_idx !== nothing

        # Check shell section
        shell_sections = filter(p -> isa(p, AbaqusReader.ShellSection), model.properties)
        @test length(shell_sections) == 1
        @test shell_sections[1].material_name == :STEEL

        # Check steps
        @test length(model.steps) == 2
        @test model.steps[1].kind == :STATIC
        @test model.steps[2].kind == :STATIC
    end

    @testset "Tensile test - mesh parsing" begin
        mesh = abaqus_read_mesh(joinpath(testdir, "tensile_test.inp"))

        # Check nodes
        @test haskey(mesh, "nodes")
        @test length(mesh["nodes"]) == 12

        # Check CAX4 axisymmetric elements
        @test haskey(mesh, "elements")
        @test haskey(mesh["elements"], "CAX4")
        @test length(mesh["elements"]["CAX4"]) == 6

        # Check sets
        @test haskey(mesh, "node_sets")
        @test haskey(mesh["node_sets"], "BOTTOM")
        @test haskey(mesh["node_sets"], "TOP")
        @test haskey(mesh["node_sets"], "AXIS")
    end

    @testset "Tensile test - model parsing" begin
        model = abaqus_read_model(joinpath(testdir, "tensile_test.inp"))

        # Check heading
        @test model.heading !== nothing

        # Check material
        @test length(model.materials) == 1
        @test haskey(model.materials, :ALUMINUM)
        mat = model.materials[:ALUMINUM]
        @test mat.name == "ALUMINUM"
        @test length(mat.properties) >= 4

        # Check for expansion property
        expansion_idx = findfirst(p -> isa(p, AbaqusReader.Expansion), mat.properties)
        @test expansion_idx !== nothing

        # Check step with name
        @test length(model.steps) == 1
        @test model.steps[1].name == "TENSION_TEST"
        @test haskey(model.steps[1].options, "NLGEOM")
        @test haskey(model.steps[1].options, "INC")

        # Check boundary conditions
        @test length(model.boundary_conditions) > 0
    end

    @testset "Thermal conduction - mesh parsing" begin
        mesh = abaqus_read_mesh(joinpath(testdir, "thermal_conduction.inp"))

        # Check nodes
        @test haskey(mesh, "nodes")
        @test length(mesh["nodes"]) == 6

        # Check DC3D8 thermal elements
        @test haskey(mesh, "elements")
        @test haskey(mesh["elements"], "DC3D8")
        @test length(mesh["elements"]["DC3D8"]) == 5

        # Check sets
        @test haskey(mesh, "node_sets")
        @test haskey(mesh["node_sets"], "LEFT")
        @test haskey(mesh["node_sets"], "RIGHT")
    end

    @testset "Thermal conduction - model parsing" begin
        model = abaqus_read_model(joinpath(testdir, "thermal_conduction.inp"))

        # Check material with thermal properties
        @test length(model.materials) == 1
        @test haskey(model.materials, :COPPER)
        mat = model.materials[:COPPER]
        @test mat.name == "COPPER"

        # Material should have conductivity, specific heat, density
        # Note: Our parser may not support CONDUCTIVITY and SPECIFIC HEAT yet
        # but it should parse without errors

        # Check step
        @test length(model.steps) == 1
        @test model.steps[1].name == "HEATING"
    end

    @testset "Contact hertz - mesh parsing" begin
        mesh = abaqus_read_mesh(joinpath(testdir, "contact_hertz.inp"))

        # Check nodes
        @test haskey(mesh, "nodes")
        @test length(mesh["nodes"]) > 10

        # Check CAX4 elements
        @test haskey(mesh, "elements")
        @test haskey(mesh["elements"], "CAX4")
        @test length(mesh["elements"]["CAX4"]) == 10

        # Check element sets
        @test haskey(mesh, "element_sets")
        @test haskey(mesh["element_sets"], "SPHERE")
        @test haskey(mesh["element_sets"], "PLATE")

        # Check surfaces
        @test haskey(mesh, "surfaces")
        @test haskey(mesh["surfaces"], "SPHERE_SURF")
        @test haskey(mesh["surfaces"], "PLATE_SURF")
    end

    @testset "Contact hertz - model parsing" begin
        model = abaqus_read_model(joinpath(testdir, "contact_hertz.inp"))

        # Check materials
        @test length(model.materials) == 2
        @test haskey(model.materials, :STEEL_SPHERE)
        @test haskey(model.materials, :STEEL_PLATE)

        # Check solid sections
        solid_sections = filter(p -> isa(p, AbaqusReader.SolidSection), model.properties)
        @test length(solid_sections) == 2

        # Check step
        @test length(model.steps) == 1
        @test model.steps[1].name == "CONTACT_STEP"
        @test haskey(model.steps[1].options, "NLGEOM")

        # Check boundary conditions
        @test length(model.boundary_conditions) > 0
    end
end
