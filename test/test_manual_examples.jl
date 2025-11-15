using Test
using AbaqusReader

@testset "ABAQUS Manual Examples - Model Parsing" begin
    
    testdir = joinpath(@__DIR__, "test_manual_examples")
    
    @testset "Static analysis - Cantilever beam" begin
        filepath = joinpath(testdir, "static_analysis.inp")
        
        # Test that parsing doesn't throw
        model = @test_nowarn abaqus_read_model(filepath)
        
        # Validate heading
        @test model.heading !== nothing
        @test contains(model.heading, "cantilever")
        
        # Validate mesh
        @test length(model.mesh.nodes) == 16
        @test length(model.mesh.elements) == 3
        @test haskey(model.mesh.node_sets, "FIXED")
        @test haskey(model.mesh.node_sets, "LOAD")
        @test haskey(model.mesh.element_sets, "BEAM")
        
        # Validate material
        @test length(model.materials) == 1
        @test haskey(model.materials, :STEEL)
        steel = model.materials[:STEEL]
        @test steel.name == :STEEL
        
        # Check elastic property
        elastic = findfirst(p -> isa(p, AbaqusReader.Elastic), steel.properties)
        @test elastic !== nothing
        @test steel.properties[elastic].E == 200.0e9
        @test steel.properties[elastic].nu == 0.3
        
        # Check density
        density = findfirst(p -> isa(p, AbaqusReader.Density), steel.properties)
        @test density !== nothing
        @test steel.properties[density].density == 7800.0
        
        # Validate solid section
        solid_sections = filter(p -> isa(p, AbaqusReader.SolidSection), model.properties)
        @test length(solid_sections) == 1
        @test solid_sections[1].element_set == :BEAM
        @test solid_sections[1].material_name == :STEEL
        
        # Steps
        @test length(model.steps) == 1
        step = model.steps[1]
        @test step isa AbaqusReader.Step
        @test step.name == "APPLY_LOAD"
        @test step.kind == :STATIC
        
        # Validate boundary conditions (defined within step)
        @test length(step.boundary_conditions) > 0
    end
    
    @testset "Frequency analysis - Modal" begin
        filepath = joinpath(testdir, "frequency_analysis.inp")
        
        model = @test_nowarn abaqus_read_model(filepath)
        
        # Validate heading
        @test model.heading !== nothing
        @test contains(lowercase(model.heading), "modal")
        
        # Validate mesh  
        @test length(model.mesh.nodes) == 12
        @test length(model.mesh.elements) == 2
        
        # Validate material
        @test length(model.materials) == 1
        @test haskey(model.materials, :ALUMINUM)
        aluminum = model.materials[:ALUMINUM]
        
        elastic = findfirst(p -> isa(p, AbaqusReader.Elastic), aluminum.properties)
        @test elastic !== nothing
        @test aluminum.properties[elastic].E == 70.0e9
        
        # Validate step type
        @test length(model.steps) == 1
        @test model.steps[1].name == "MODAL_ANALYSIS"
        @test model.steps[1].kind == :FREQUENCY
    end
    
    @testset "Plastic analysis - Nonlinear" begin
        filepath = joinpath(testdir, "plastic_analysis.inp")
        
        model = @test_nowarn abaqus_read_model(filepath)
        
        # Validate heading
        @test model.heading !== nothing
        
        # Validate mesh - CPE4 elements
        @test length(model.mesh.elements) == 2
        
        # Validate material with plasticity
        @test length(model.materials) == 1
        @test haskey(model.materials, :MILD_STEEL)
        steel = model.materials[:MILD_STEEL]
        
        # Check plastic property
        plastic = findfirst(p -> isa(p, AbaqusReader.Plastic), steel.properties)
        @test plastic !== nothing
        @test length(steel.properties[plastic].table) == 4
        @test steel.properties[plastic].table[1] == (250.0e6, 0.0)
        @test steel.properties[plastic].table[4] == (400.0e6, 0.30)
        
        # Validate multiple steps
        @test length(model.steps) == 2
        @test model.steps[1].name == "LOAD_STEP_1"
        @test model.steps[2].name == "UNLOAD"
        
        # Check NLGEOM option
        @test haskey(model.steps[1].options, "NLGEOM")
        @test model.steps[1].options["NLGEOM"] == "YES"
    end
    
    @testset "Shell analysis" begin
        filepath = joinpath(testdir, "shell_analysis.inp")
        
        model = @test_nowarn abaqus_read_model(filepath)
        
        # Validate mesh - S4R shell elements
        @test length(model.mesh.elements) == 6
        
        # Validate material
        @test length(model.materials) == 1
        @test haskey(model.materials, :COMPOSITE)
        
        # Validate shell section
        shell_sections = filter(p -> isa(p, AbaqusReader.ShellSection), model.properties)
        @test length(shell_sections) == 1
        @test shell_sections[1].element_set == :SHELL_PART
        @test shell_sections[1].material_name == :COMPOSITE
        @test shell_sections[1].thickness == 2.5
        @test shell_sections[1].num_integration_points == 5
        
        # Validate step
        @test length(model.steps) == 1
        @test model.steps[1].name == "PRESSURE_LOAD"
    end
    
    @testset "Multi-material advanced features" begin
        filepath = joinpath(testdir, "multimaterial_advanced.inp")
        
        # Note: This file has element-set-based SURFACE definitions which generate warnings
        model = abaqus_read_model(filepath)
        
        # Validate heading
        @test model.heading !== nothing
        
        # Validate mesh
        @test length(model.mesh.elements) == 2
        @test haskey(model.mesh.element_sets, "ZONE_A")
        @test haskey(model.mesh.element_sets, "ZONE_B")
        @test haskey(model.mesh.element_sets, "ALL_ELEMENTS")
        
        # Note: Element-set-based surfaces not yet fully supported, so TOP_SURFACE won't be in surface_sets
        
        # Validate two materials
        @test length(model.materials) == 2
        @test haskey(model.materials, :STEEL_HIGH_STRENGTH)
        @test haskey(model.materials, :ALUMINUM_ALLOY)
        
        # Check steel properties
        steel = model.materials[:STEEL_HIGH_STRENGTH]
        
        elastic = findfirst(p -> isa(p, AbaqusReader.Elastic), steel.properties)
        @test elastic !== nothing
        
        plastic = findfirst(p -> isa(p, AbaqusReader.Plastic), steel.properties)
        @test plastic !== nothing
        @test length(steel.properties[plastic].table) == 3
        
        density = findfirst(p -> isa(p, AbaqusReader.Density), steel.properties)
        @test density !== nothing
        
        expansion = findfirst(p -> isa(p, AbaqusReader.Expansion), steel.properties)
        @test expansion !== nothing
        @test steel.properties[expansion].alpha == 12.0e-6
        
        damping = findfirst(p -> isa(p, AbaqusReader.Damping), steel.properties)
        @test damping !== nothing
        @test steel.properties[damping].alpha == 0.05
        @test steel.properties[damping].beta == 0.001
        
        # Check aluminum properties
        aluminum = model.materials[:ALUMINUM_ALLOY]
        
        plastic_al = findfirst(p -> isa(p, AbaqusReader.Plastic), aluminum.properties)
        @test plastic_al !== nothing
        
        expansion_al = findfirst(p -> isa(p, AbaqusReader.Expansion), aluminum.properties)
        @test expansion_al !== nothing
        
        # Validate solid sections
        solid_sections = filter(p -> isa(p, AbaqusReader.SolidSection), model.properties)
        @test length(solid_sections) == 2
        
        # Check section with controls
        section_with_controls = findfirst(s -> s.controls !== nothing, solid_sections)
        @test section_with_controls !== nothing
        @test solid_sections[section_with_controls].controls == :HOURGLASS_CONTROL
        
        # Validate step
        @test length(model.steps) == 1
        @test model.steps[1].name == "LOADING"
        @test haskey(model.steps[1].options, "NLGEOM")
        @test haskey(model.steps[1].options, "INC")
    end
    
    @testset "Error handling - Unsupported keywords" begin
        # Test that parser handles unknown keywords gracefully
        # Create a test file with an unsupported keyword
        tmpfile = joinpath(testdir, "test_unsupported.inp")
        write(tmpfile, """
*HEADING
Test unsupported keyword
*NODE
1, 0.0, 0.0, 0.0
2, 1.0, 0.0, 0.0
*ELEMENT, TYPE=C3D8, ELSET=TEST
1, 1, 2, 2, 1, 1, 2, 2, 1
*MATERIAL, NAME=MAT1
*ELASTIC
200.0E9, 0.3
*SOLID SECTION, ELSET=TEST, MATERIAL=MAT1
*STEP
*STATIC
*UNSUPPORTED_KEYWORD_XYZ
Some data here
*END STEP
""")
        
        # Should parse without throwing, but may warn about unknown keyword
        model = @test_nowarn abaqus_read_model(tmpfile)
        @test model !== nothing
        
        # Clean up
        rm(tmpfile, force=true)
    end
end

@testset "Parser robustness - Edge cases" begin
    
    testdir = joinpath(@__DIR__, "test_manual_examples")
    
    @testset "Empty sections" begin
        tmpfile = joinpath(testdir, "test_empty.inp")
        write(tmpfile, """
*HEADING
*NODE
1, 0.0, 0.0, 0.0
*ELEMENT, TYPE=C3D8, ELSET=E1
1, 1, 1, 1, 1, 1, 1, 1, 1
*MATERIAL, NAME=M1
*ELASTIC
200.0E9, 0.3
*SOLID SECTION, ELSET=E1, MATERIAL=M1
*STEP
*STATIC
*END STEP
""")
        
        model = @test_nowarn abaqus_read_model(tmpfile)
        @test model.heading === nothing  # Empty heading section
        
        rm(tmpfile, force=true)
    end
    
    @testset "Comments and blank lines" begin
        tmpfile = joinpath(testdir, "test_comments.inp")
        write(tmpfile, """
** This is a comment
*HEADING
Test with comments
** Another comment

*NODE
** Node definitions
1, 0.0, 0.0, 0.0

2, 1.0, 0.0, 0.0
*ELEMENT, TYPE=C3D8, ELSET=E1
** Element
1, 1, 2, 2, 1, 1, 2, 2, 1

*MATERIAL, NAME=M1
** Material properties
*ELASTIC
200.0E9, 0.3
*SOLID SECTION, ELSET=E1, MATERIAL=M1
*STEP
*STATIC
*END STEP
""")
        
        model = @test_nowarn abaqus_read_model(tmpfile)
        @test length(model.mesh.nodes) == 2
        
        rm(tmpfile, force=true)
    end
    
    @testset "Case sensitivity" begin
        tmpfile = joinpath(testdir, "test_case.inp")
        write(tmpfile, """
*Heading
Mixed case test
*Node
1, 0.0, 0.0, 0.0
*Element, Type=C3D8, Elset=E1
1, 1, 1, 1, 1, 1, 1, 1, 1
*Material, Name=M1
*Elastic
200.0E9, 0.3
*Solid Section, Elset=E1, Material=M1
*Step
*Static
*End Step
""")
        
        # Parser should handle mixed case (keywords are uppercased)
        model = @test_nowarn abaqus_read_model(tmpfile)
        @test length(model.materials) == 1
        
        rm(tmpfile, force=true)
    end
end
