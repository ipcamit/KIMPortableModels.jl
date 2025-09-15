# test_species.jl - Test species handling functions

@testset "Species Handling" begin

    @testset "Species Symbols" begin
        # Test that SpeciesSymbols contains expected elements
        @test "H" in KIMPortableModels.SpeciesSymbols
        @test "He" in KIMPortableModels.SpeciesSymbols
        @test "Si" in KIMPortableModels.SpeciesSymbols
        @test "C" in KIMPortableModels.SpeciesSymbols
        @test "O" in KIMPortableModels.SpeciesSymbols
        @test "Fe" in KIMPortableModels.SpeciesSymbols
        @test "Cu" in KIMPortableModels.SpeciesSymbols
        @test "Ar" in KIMPortableModels.SpeciesSymbols
        @test "electron" in KIMPortableModels.SpeciesSymbols

        # Test ordering (electron should be first)
        @test KIMPortableModels.SpeciesSymbols[1] == "electron"
        @test KIMPortableModels.SpeciesSymbols[2] == "H"  # Hydrogen
        @test KIMPortableModels.SpeciesSymbols[3] == "He" # Helium

        # Test that it includes high-Z elements
        @test "Og" in KIMPortableModels.SpeciesSymbols  # Oganesson (element 118)
    end

    if isdefined(KIMPortableModels, :libkim) && KIMPortableModels.libkim != ""
        @testset "Species Number Functions" begin
            # Test conversion from string to species number
            h_code = KIMPortableModels.get_species_number("H")
            @test h_code isa Int32
            @test h_code >= 0

            si_code = KIMPortableModels.get_species_number("Si")
            @test si_code isa Int32
            @test si_code >= 0

            # Different elements should have different codes
            @test h_code != si_code

            # Test conversion back to string
            @test KIMPortableModels.get_species_symbol(h_code) == "H"
            @test KIMPortableModels.get_species_symbol(si_code) == "Si"

            # Test species validation functions
            @test KIMPortableModels.species_name_known(h_code) == true
            @test KIMPortableModels.species_name_known(si_code) == true

            # Test species comparison
            @test KIMPortableModels.species_name_equal(h_code, h_code) == true
            @test KIMPortableModels.species_name_equal(h_code, si_code) == false
            @test KIMPortableModels.species_name_not_equal(h_code, si_code) == true
            @test KIMPortableModels.species_name_not_equal(h_code, h_code) == false
        end

        @testset "Species Mapping Functions" begin
            # These tests require a KIM model, so we'll create a mock model
            # or skip if model creation fails

            # Test get_species_codes_from_model would require a real model
            # For now, we'll test the utility functions that don't require models

            species_list = ["H", "He", "Li", "C", "Si"]
            unique_species = unique(species_list)
            @test length(unique_species) == 5
            @test all(s -> s in KIMPortableModels.SpeciesSymbols, species_list)
        end
    end

    @testset "Species Validation" begin
        # Test input validation for species functions
        @test_nowarn KIMPortableModels.SpeciesSymbols[1]  # Should not throw
        @test length(KIMPortableModels.SpeciesSymbols) > 100  # Should have many elements

        # Test that all symbols are strings
        @test all(s -> s isa String, KIMPortableModels.SpeciesSymbols)

        # Test that all symbols are non-empty
        @test all(s -> length(s) > 0, KIMPortableModels.SpeciesSymbols)

        # Test that common elements are present in expected positions
        h_index = findfirst(s -> s == "H", KIMPortableModels.SpeciesSymbols)
        he_index = findfirst(s -> s == "He", KIMPortableModels.SpeciesSymbols)
        c_index = findfirst(s -> s == "C", KIMPortableModels.SpeciesSymbols)

        @test h_index == 2   # Hydrogen should be second (after electron)
        @test he_index == 3  # Helium should be third
        @test c_index == 7   # Carbon should be 7th (atomic number 6 + 1 for electron)
    end
end
