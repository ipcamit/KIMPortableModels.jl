# test_constants.jl - Test KIMPortableModels constants and enumerations

@testset "Constants and Enumerations" begin

    @testset "Enumeration Values" begin
        # Test that enums have correct integer values (matching KIM-API C constants)
        @test Int(KIMPortableModels.zeroBased) == 0
        @test Int(KIMPortableModels.oneBased) == 1

        @test Int(KIMPortableModels.A) == 1
        @test Int(KIMPortableModels.Bohr) == 2
        @test Int(KIMPortableModels.eV) == 3
        @test Int(KIMPortableModels.e) == 2
        @test Int(KIMPortableModels.K) == 1
        @test Int(KIMPortableModels.ps) == 2

        @test Int(KIMPortableModels.numberOfParticles) == 0
        @test Int(KIMPortableModels.particleSpeciesCodes) == 1
        @test Int(KIMPortableModels.coordinates) == 3
        @test Int(KIMPortableModels.partialEnergy) == 4
        @test Int(KIMPortableModels.partialForces) == 5

        @test Int(KIMPortableModels.GetNeighborList) == 0
        @test Int(KIMPortableModels.c) == 1
        @test Int(KIMPortableModels.required) == 2
        @test Int(KIMPortableModels.optional) == 3
        @test Int(KIMPortableModels.notSupported) == 1
    end

    @testset "Unit Styles" begin
        # Test predefined unit styles
        metal = KIMPortableModels.UNIT_STYLES.metal
        @test metal.length == KIMPortableModels.A
        @test metal.energy == KIMPortableModels.eV
        @test metal.charge == KIMPortableModels.e
        @test metal.temperature == KIMPortableModels.K
        @test metal.time == KIMPortableModels.ps

        real = KIMPortableModels.UNIT_STYLES.real
        @test real.length == KIMPortableModels.A
        @test real.energy == KIMPortableModels.kcal_mol
        @test real.time == KIMPortableModels.fs

        si = KIMPortableModels.UNIT_STYLES.si
        @test si.length == KIMPortableModels.m
        @test si.energy == KIMPortableModels.J
        @test si.charge == KIMPortableModels.C
        @test si.time == KIMPortableModels.s

        electron = KIMPortableModels.UNIT_STYLES.electron
        @test electron.length == KIMPortableModels.Bohr
        @test electron.energy == KIMPortableModels.Hartree
        @test electron.time == KIMPortableModels.fs
    end

    @testset "Unit Style Function" begin
        # Test get_lammps_style_units function
        metal_units = KIMPortableModels.get_lammps_style_units(:metal)
        @test metal_units.length == KIMPortableModels.A
        @test metal_units.energy == KIMPortableModels.eV

        real_units = KIMPortableModels.get_lammps_style_units(:real)
        @test real_units.energy == KIMPortableModels.kcal_mol

        si_units = KIMPortableModels.get_lammps_style_units(:si)
        @test si_units.length == KIMPortableModels.m
        @test si_units.energy == KIMPortableModels.J

        # Test error for invalid style
        @test_throws ErrorException KIMPortableModels.get_lammps_style_units(:invalid)
    end

    if isdefined(KIMPortableModels, :libkim) && KIMPortableModels.libkim != ""
        @testset "KIM-API Constant Functions" begin
            # Test constant lookup functions (require KIM-API library)
            @test KIMPortableModels.get_numbering("zeroBased") == 0
            @test KIMPortableModels.get_numbering("oneBased") == 1

            @test KIMPortableModels.get_length_unit("A") == 1
            @test KIMPortableModels.get_length_unit("Bohr") == 2

            @test KIMPortableModels.get_energy_unit("eV") == 3
            @test KIMPortableModels.get_energy_unit("J") == 5

            @test KIMPortableModels.get_charge_unit("e") == 2
            @test KIMPortableModels.get_charge_unit("C") == 1

            @test KIMPortableModels.get_temperature_unit("K") == 1

            @test KIMPortableModels.get_time_unit("fs") == 1
            @test KIMPortableModels.get_time_unit("ps") == 2
        end

        @testset "Reverse Lookup Functions" begin
            # Test constant to string conversion
            @test KIMPortableModels.numbering_to_string(0) == "zeroBased"
            @test KIMPortableModels.numbering_to_string(1) == "oneBased"

            @test KIMPortableModels.length_unit_to_string(1) == "A"
            @test KIMPortableModels.length_unit_to_string(2) == "Bohr"

            @test KIMPortableModels.energy_unit_to_string(3) == "eV"
            @test KIMPortableModels.energy_unit_to_string(5) == "J"

            # Test unknown values
            @test KIMPortableModels.numbering_to_string(999) == "unknown"
            @test KIMPortableModels.length_unit_to_string(-1) == "unknown"
        end
    end
end
