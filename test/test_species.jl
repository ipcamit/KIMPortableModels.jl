# test_species.jl - Test species handling functions

@testset "Species Handling" begin

    @testset "Species Symbols" begin
        # Test that SpeciesSymbols contains expected elements
        @test "H" in KIMJulia.SpeciesSymbols
        @test "He" in KIMJulia.SpeciesSymbols
        @test "Si" in KIMJulia.SpeciesSymbols
        @test "C" in KIMJulia.SpeciesSymbols
        @test "O" in KIMJulia.SpeciesSymbols
        @test "Fe" in KIMJulia.SpeciesSymbols
        @test "Cu" in KIMJulia.SpeciesSymbols
        @test "Ar" in KIMJulia.SpeciesSymbols
        @test "electron" in KIMJulia.SpeciesSymbols

        # Test ordering (electron should be first)
        @test KIMJulia.SpeciesSymbols[1] == "electron"
        @test KIMJulia.SpeciesSymbols[2] == "H"  # Hydrogen
        @test KIMJulia.SpeciesSymbols[3] == "He" # Helium

        # Test that it includes high-Z elements
        @test "Og" in KIMJulia.SpeciesSymbols  # Oganesson (element 118)
    end

    if isdefined(KIMJulia, :libkim) && KIMJulia.libkim != ""
        @testset "Species Number Functions" begin
            # Test conversion from string to species number
            h_code = KIMJulia.get_species_number("H")
            @test h_code isa Int32
            @test h_code >= 0

            si_code = KIMJulia.get_species_number("Si")
            @test si_code isa Int32
            @test si_code >= 0

            # Different elements should have different codes
            @test h_code != si_code

            # Test conversion back to string
            @test KIMJulia.get_species_symbol(h_code) == "H"
            @test KIMJulia.get_species_symbol(si_code) == "Si"

            # Test species validation functions
            @test KIMJulia.species_name_known(h_code) == true
            @test KIMJulia.species_name_known(si_code) == true

            # Test species comparison
            @test KIMJulia.species_name_equal(h_code, h_code) == true
            @test KIMJulia.species_name_equal(h_code, si_code) == false
            @test KIMJulia.species_name_not_equal(h_code, si_code) == true
            @test KIMJulia.species_name_not_equal(h_code, h_code) == false
        end

        @testset "Species Mapping Functions" begin
            # These tests require a KIM model, so we'll create a mock model
            # or skip if model creation fails

            # Test get_species_codes_from_model would require a real model
            # For now, we'll test the utility functions that don't require models

            species_list = ["H", "He", "Li", "C", "Si"]
            unique_species = unique(species_list)
            @test length(unique_species) == 5
            @test all(s -> s in KIMJulia.SpeciesSymbols, species_list)
        end
    end

    @testset "Species Validation" begin
        # Test input validation for species functions
        @test_nowarn KIMJulia.SpeciesSymbols[1]  # Should not throw
        @test length(KIMJulia.SpeciesSymbols) > 100  # Should have many elements

        # Test that all symbols are strings
        @test all(s -> s isa String, KIMJulia.SpeciesSymbols)

        # Test that all symbols are non-empty
        @test all(s -> length(s) > 0, KIMJulia.SpeciesSymbols)

        # Test that common elements are present in expected positions
        h_index = findfirst(s -> s == "H", KIMJulia.SpeciesSymbols)
        he_index = findfirst(s -> s == "He", KIMJulia.SpeciesSymbols)
        c_index = findfirst(s -> s == "C", KIMJulia.SpeciesSymbols)

        @test h_index == 2   # Hydrogen should be second (after electron)
        @test he_index == 3  # Helium should be third
        @test c_index == 7   # Carbon should be 7th (atomic number 6 + 1 for electron)
    end
end
