using Test
using AbaqusReader

@testset "Comprehensive parsing tests" begin

    @testset "Plate with hole - mesh parsing" begin
        mesh = abaqus_read_mesh("test_comprehensive/plate_with_hole.inp")

        # Check nodes
        @test haskey(mesh, "nodes")
        @test length(mesh["nodes"]) > 0

        # Check elements
        @test haskey(mesh, "elements")
        @test haskey(mesh["elements"], "S4R")  # Shell elements
        @test haskey(mesh["elements"], "MASS")  # Point mass
        @test length(mesh["elements"]["S4R"]) > 0

        # Check element sets
        @test haskey(mesh, "element_sets")
        @test haskey(mesh["element_sets"], "PLATE")
        @test haskey(mesh["element_sets"], "HOLE_EDGE")

        # Check node sets
        @test haskey(mesh, "node_sets")
        @test haskey(mesh["node_sets"], "FIXED_EDGE")
        @test haskey(mesh["node_sets"], "LOADED_EDGE")

        # Check surfaces
        @test haskey(mesh, "surfaces")
        @test haskey(mesh["surfaces"], "BOTTOM_SURFACE")
    end

    @testset "Plate with hole - model parsing" begin
        model = abaqus_read_model("test_comprehensive/plate_with_hole.inp")

        # Check materials
        @test length(model.materials) == 2
        material_names = [m.name for m in model.materials]
        @test "STEEL" in material_names
        @test "ALUMINUM" in material_names

        # Check STEEL material properties
        steel = model.materials[findfirst(m -> m.name == "STEEL", model.materials)]
        @test length(steel.properties) >= 1

        # Find elastic property
        elastic_prop = findfirst(p -> isa(p, AbaqusReader.Elastic), steel.properties)
        @test elastic_prop !== nothing
        if elastic_prop !== nothing
            elastic = steel.properties[elastic_prop]
            @test elastic.youngs_modulus == 200.0e9
            @test elastic.poissons_ratio == 0.3
        end

        # Find density property
        density_prop = findfirst(p -> isa(p, AbaqusReader.Density), steel.properties)
        @test density_prop !== nothing
        if density_prop !== nothing
            density = steel.properties[density_prop]
            @test density.density == 7850.0
        end

        # Find expansion property
        expansion_prop = findfirst(p -> isa(p, AbaqusReader.Expansion), steel.properties)
        @test expansion_prop !== nothing
        if expansion_prop !== nothing
            expansion = steel.properties[expansion_prop]
            @test expansion.alpha == 12.0e-6
        end

        # Check ALUMINUM material properties
        aluminum = model.materials[findfirst(m -> m.name == "ALUMINUM", model.materials)]

        # Should have elastic
        elastic_prop = findfirst(p -> isa(p, AbaqusReader.Elastic), aluminum.properties)
        @test elastic_prop !== nothing

        # Should have plastic
        plastic_prop = findfirst(p -> isa(p, AbaqusReader.Plastic), aluminum.properties)
        @test plastic_prop !== nothing
        if plastic_prop !== nothing
            plastic = aluminum.properties[plastic_prop]
            @test length(plastic.table) == 2
            @test plastic.table[1] == (200.0e6, 0.0)
            @test plastic.table[2] == (250.0e6, 0.05)
        end

        # Check shell section
        shell_sections = filter(p -> isa(p, AbaqusReader.ShellSection), model.properties)
        @test length(shell_sections) >= 1
        if length(shell_sections) > 0
            shell = shell_sections[1]
            @test shell.element_set == :PLATE
            @test shell.material_name == :STEEL
            @test shell.thickness == 0.005
            @test shell.num_integration_points == 5
        end

        # Check mass section
        mass_sections = filter(p -> isa(p, AbaqusReader.MassSection), model.properties)
        @test length(mass_sections) >= 1
        if length(mass_sections) > 0
            mass = mass_sections[1]
            @test mass.element_set == :POINT_MASS
            @test mass.mass == 10.0
        end

        # Check steps
        @test length(model.steps) == 2
        @test model.steps[1].name == "LoadStep1"
        @test model.steps[2].name == "LoadStep2"

        # Check boundary conditions
        @test length(model.boundary_conditions) > 0

        # Check loads (should have CLOAD, DLOAD, DSLOAD)
        @test length(model.loads) > 0
    end

    @testset "Cantilever beam - mesh parsing" begin
        mesh = abaqus_read_mesh("test_comprehensive/cantilever_beam.inp")

        # Check nodes
        @test haskey(mesh, "nodes")
        @test length(mesh["nodes"]) > 0

        # Check elements
        @test haskey(mesh, "elements")
        @test haskey(mesh["elements"], "C3D8")  # Linear brick
        @test haskey(mesh["elements"], "C3D20R")  # Quadratic brick
        @test length(mesh["elements"]["C3D8"]) > 0
        @test length(mesh["elements"]["C3D20R"]) > 0

        # Check element sets
        @test haskey(mesh, "element_sets")
        @test haskey(mesh["element_sets"], "BEAM_BODY")
        @test haskey(mesh["element_sets"], "REFINED_ZONE")

        # Check node sets
        @test haskey(mesh, "node_sets")
        @test haskey(mesh["node_sets"], "FIXED_END")
        @test haskey(mesh["node_sets"], "LOADED_END")
        @test haskey(mesh["node_sets"], "MONITOR_POINT")
    end

    @testset "Cantilever beam - model parsing" begin
        model = abaqus_read_model("test_comprehensive/cantilever_beam.inp")

        # Check materials
        @test length(model.materials) >= 1
        material_names = [m.name for m in model.materials]
        @test "STEEL_MILD" in material_names

        # Check STEEL_MILD material
        steel = model.materials[findfirst(m -> m.name == "STEEL_MILD", model.materials)]

        # Should have elastic
        elastic_prop = findfirst(p -> isa(p, AbaqusReader.Elastic), steel.properties)
        @test elastic_prop !== nothing

        # Should have plastic
        plastic_prop = findfirst(p -> isa(p, AbaqusReader.Plastic), steel.properties)
        @test plastic_prop !== nothing
        if plastic_prop !== nothing
            plastic = steel.properties[plastic_prop]
            @test length(plastic.table) == 3
        end

        # Should have density
        density_prop = findfirst(p -> isa(p, AbaqusReader.Density), steel.properties)
        @test density_prop !== nothing

        # Should have damping
        damping_prop = findfirst(p -> isa(p, AbaqusReader.Damping), steel.properties)
        @test damping_prop !== nothing
        if damping_prop !== nothing
            damping = steel.properties[damping_prop]
            @test damping.alpha == 0.1
            @test damping.beta == 0.001
        end

        # Check solid sections with controls
        solid_sections = filter(p -> isa(p, AbaqusReader.SolidSection), model.properties)
        @test length(solid_sections) >= 2

        # Check that at least one has controls
        has_controls = any(s -> s.controls !== nothing, solid_sections)
        @test has_controls

        # Check steps
        @test length(model.steps) == 3

        # First step should be static
        @test model.steps[1].name == "Apply_Load"

        # Second step should be frequency
        @test model.steps[2].name == "Frequency_Analysis"

        # Third step should be unload
        @test model.steps[3].name == "Unload"

        # Check boundary conditions
        @test length(model.boundary_conditions) > 0

        # Check loads
        @test length(model.loads) > 0
    end
end
