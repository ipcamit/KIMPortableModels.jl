# test_species.jl - Test species handling functions

@testset "Species Handling" begin

    @testset "Species Symbols" begin
        # Test that SpeciesSymbols contains expected elements
        @test "H" in KIM.SpeciesSymbols
        @test "He" in KIM.SpeciesSymbols
        @test "Si" in KIM.SpeciesSymbols
        @test "C" in KIM.SpeciesSymbols
        @test "O" in KIM.SpeciesSymbols
        @test "Fe" in KIM.SpeciesSymbols
        @test "Cu" in KIM.SpeciesSymbols
        @test "Ar" in KIM.SpeciesSymbols
        @test "electron" in KIM.SpeciesSymbols

        # Test ordering (electron should be first)
        @test KIM.SpeciesSymbols[1] == "electron"
        @test KIM.SpeciesSymbols[2] == "H"  # Hydrogen
        @test KIM.SpeciesSymbols[3] == "He" # Helium

        # Test that it includes high-Z elements
        @test "Og" in KIM.SpeciesSymbols  # Oganesson (element 118)
    end

    if isdefined(KIM, :libkim) && KIM.libkim != ""
        @testset "Species Number Functions" begin
            # Test conversion from string to species number
            h_code = KIM.get_species_number("H")
            @test h_code isa Int32
            @test h_code >= 0

            si_code = KIM.get_species_number("Si")
            @test si_code isa Int32
            @test si_code >= 0

            # Different elements should have different codes
            @test h_code != si_code

            # Test conversion back to string
            @test KIM.get_species_symbol(h_code) == "H"
            @test KIM.get_species_symbol(si_code) == "Si"

            # Test species validation functions
            @test KIM.species_name_known(h_code) == true
            @test KIM.species_name_known(si_code) == true

            # Test species comparison
            @test KIM.species_name_equal(h_code, h_code) == true
            @test KIM.species_name_equal(h_code, si_code) == false
            @test KIM.species_name_not_equal(h_code, si_code) == true
            @test KIM.species_name_not_equal(h_code, h_code) == false
        end

        @testset "Species Mapping Functions" begin
            # These tests require a KIM model, so we'll create a mock model
            # or skip if model creation fails

            # Test get_species_codes_from_model would require a real model
            # For now, we'll test the utility functions that don't require models

            species_list = ["H", "He", "Li", "C", "Si"]
            unique_species = unique(species_list)
            @test length(unique_species) == 5
            @test all(s -> s in KIM.SpeciesSymbols, species_list)
        end
    end

    @testset "Species Validation" begin
        # Test input validation for species functions
        @test_nowarn KIM.SpeciesSymbols[1]  # Should not throw
        @test length(KIM.SpeciesSymbols) > 100  # Should have many elements

        # Test that all symbols are strings
        @test all(s -> s isa String, KIM.SpeciesSymbols)

        # Test that all symbols are non-empty
        @test all(s -> length(s) > 0, KIM.SpeciesSymbols)

        # Test that common elements are present in expected positions
        h_index = findfirst(s -> s == "H", KIM.SpeciesSymbols)
        he_index = findfirst(s -> s == "He", KIM.SpeciesSymbols)
        c_index = findfirst(s -> s == "C", KIM.SpeciesSymbols)

        @test h_index == 2   # Hydrogen should be second (after electron)
        @test he_index == 3  # Helium should be third
        @test c_index == 7   # Carbon should be 7th (atomic number 6 + 1 for electron)
    end
end
