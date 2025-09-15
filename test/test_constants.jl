# test_constants.jl - Test KIM constants and enumerations

@testset "Constants and Enumerations" begin

    @testset "Enumeration Values" begin
        # Test that enums have correct integer values (matching KIM-API C constants)
        @test Int(KIM.zeroBased) == 0
        @test Int(KIM.oneBased) == 1

        @test Int(KIM.A) == 1
        @test Int(KIM.Bohr) == 2
        @test Int(KIM.eV) == 3
        @test Int(KIM.e) == 2
        @test Int(KIM.K) == 1
        @test Int(KIM.ps) == 2

        @test Int(KIM.numberOfParticles) == 0
        @test Int(KIM.particleSpeciesCodes) == 1
        @test Int(KIM.coordinates) == 3
        @test Int(KIM.partialEnergy) == 4
        @test Int(KIM.partialForces) == 5

        @test Int(KIM.GetNeighborList) == 0
        @test Int(KIM.c) == 1
        @test Int(KIM.required) == 2
        @test Int(KIM.optional) == 3
        @test Int(KIM.notSupported) == 1
    end

    @testset "Unit Styles" begin
        # Test predefined unit styles
        metal = KIM.UNIT_STYLES.metal
        @test metal.length == KIM.A
        @test metal.energy == KIM.eV
        @test metal.charge == KIM.e
        @test metal.temperature == KIM.K
        @test metal.time == KIM.ps

        real = KIM.UNIT_STYLES.real
        @test real.length == KIM.A
        @test real.energy == KIM.kcal_mol
        @test real.time == KIM.fs

        si = KIM.UNIT_STYLES.si
        @test si.length == KIM.m
        @test si.energy == KIM.J
        @test si.charge == KIM.C
        @test si.time == KIM.s

        electron = KIM.UNIT_STYLES.electron
        @test electron.length == KIM.Bohr
        @test electron.energy == KIM.Hartree
        @test electron.time == KIM.fs
    end

    @testset "Unit Style Function" begin
        # Test get_lammps_style_units function
        metal_units = KIM.get_lammps_style_units(:metal)
        @test metal_units.length == KIM.A
        @test metal_units.energy == KIM.eV

        real_units = KIM.get_lammps_style_units(:real)
        @test real_units.energy == KIM.kcal_mol

        si_units = KIM.get_lammps_style_units(:si)
        @test si_units.length == KIM.m
        @test si_units.energy == KIM.J

        # Test error for invalid style
        @test_throws ErrorException KIM.get_lammps_style_units(:invalid)
    end

    if isdefined(KIM, :libkim) && KIM.libkim != ""
        @testset "KIM-API Constant Functions" begin
            # Test constant lookup functions (require KIM-API library)
            @test KIM.get_numbering("zeroBased") == 0
            @test KIM.get_numbering("oneBased") == 1

            @test KIM.get_length_unit("A") == 1
            @test KIM.get_length_unit("Bohr") == 2

            @test KIM.get_energy_unit("eV") == 3
            @test KIM.get_energy_unit("J") == 5

            @test KIM.get_charge_unit("e") == 2
            @test KIM.get_charge_unit("C") == 1

            @test KIM.get_temperature_unit("K") == 1

            @test KIM.get_time_unit("fs") == 1
            @test KIM.get_time_unit("ps") == 2
        end

        @testset "Reverse Lookup Functions" begin
            # Test constant to string conversion
            @test KIM.numbering_to_string(0) == "zeroBased"
            @test KIM.numbering_to_string(1) == "oneBased"

            @test KIM.length_unit_to_string(1) == "A"
            @test KIM.length_unit_to_string(2) == "Bohr"

            @test KIM.energy_unit_to_string(3) == "eV"
            @test KIM.energy_unit_to_string(5) == "J"

            # Test unknown values
            @test KIM.numbering_to_string(999) == "unknown"
            @test KIM.length_unit_to_string(-1) == "unknown"
        end
    end
end
