# test_constants.jl - Test KIMJulia constants and enumerations

@testset "Constants and Enumerations" begin

    @testset "Enumeration Values" begin
        # Test that enums have correct integer values (matching KIM-API C constants)
        @test Int(KIMJulia.zeroBased) == 0
        @test Int(KIMJulia.oneBased) == 1

        @test Int(KIMJulia.A) == 1
        @test Int(KIMJulia.Bohr) == 2
        @test Int(KIMJulia.eV) == 3
        @test Int(KIMJulia.e) == 2
        @test Int(KIMJulia.K) == 1
        @test Int(KIMJulia.ps) == 2

        @test Int(KIMJulia.numberOfParticles) == 0
        @test Int(KIMJulia.particleSpeciesCodes) == 1
        @test Int(KIMJulia.coordinates) == 3
        @test Int(KIMJulia.partialEnergy) == 4
        @test Int(KIMJulia.partialForces) == 5

        @test Int(KIMJulia.GetNeighborList) == 0
        @test Int(KIMJulia.c) == 1
        @test Int(KIMJulia.required) == 2
        @test Int(KIMJulia.optional) == 3
        @test Int(KIMJulia.notSupported) == 1
    end

    @testset "Unit Styles" begin
        # Test predefined unit styles
        metal = KIMJulia.UNIT_STYLES.metal
        @test metal.length == KIMJulia.A
        @test metal.energy == KIMJulia.eV
        @test metal.charge == KIMJulia.e
        @test metal.temperature == KIMJulia.K
        @test metal.time == KIMJulia.ps

        real = KIMJulia.UNIT_STYLES.real
        @test real.length == KIMJulia.A
        @test real.energy == KIMJulia.kcal_mol
        @test real.time == KIMJulia.fs

        si = KIMJulia.UNIT_STYLES.si
        @test si.length == KIMJulia.m
        @test si.energy == KIMJulia.J
        @test si.charge == KIMJulia.C
        @test si.time == KIMJulia.s

        electron = KIMJulia.UNIT_STYLES.electron
        @test electron.length == KIMJulia.Bohr
        @test electron.energy == KIMJulia.Hartree
        @test electron.time == KIMJulia.fs
    end

    @testset "Unit Style Function" begin
        # Test get_lammps_style_units function
        metal_units = KIMJulia.get_lammps_style_units(:metal)
        @test metal_units.length == KIMJulia.A
        @test metal_units.energy == KIMJulia.eV

        real_units = KIMJulia.get_lammps_style_units(:real)
        @test real_units.energy == KIMJulia.kcal_mol

        si_units = KIMJulia.get_lammps_style_units(:si)
        @test si_units.length == KIMJulia.m
        @test si_units.energy == KIMJulia.J

        # Test error for invalid style
        @test_throws ErrorException KIMJulia.get_lammps_style_units(:invalid)
    end

    if isdefined(KIMJulia, :libkim) && KIMJulia.libkim != ""
        @testset "KIM-API Constant Functions" begin
            # Test constant lookup functions (require KIM-API library)
            @test KIMJulia.get_numbering("zeroBased") == 0
            @test KIMJulia.get_numbering("oneBased") == 1

            @test KIMJulia.get_length_unit("A") == 1
            @test KIMJulia.get_length_unit("Bohr") == 2

            @test KIMJulia.get_energy_unit("eV") == 3
            @test KIMJulia.get_energy_unit("J") == 5

            @test KIMJulia.get_charge_unit("e") == 2
            @test KIMJulia.get_charge_unit("C") == 1

            @test KIMJulia.get_temperature_unit("K") == 1

            @test KIMJulia.get_time_unit("fs") == 1
            @test KIMJulia.get_time_unit("ps") == 2
        end

        @testset "Reverse Lookup Functions" begin
            # Test constant to string conversion
            @test KIMJulia.numbering_to_string(0) == "zeroBased"
            @test KIMJulia.numbering_to_string(1) == "oneBased"

            @test KIMJulia.length_unit_to_string(1) == "A"
            @test KIMJulia.length_unit_to_string(2) == "Bohr"

            @test KIMJulia.energy_unit_to_string(3) == "eV"
            @test KIMJulia.energy_unit_to_string(5) == "J"

            # Test unknown values
            @test KIMJulia.numbering_to_string(999) == "unknown"
            @test KIMJulia.length_unit_to_string(-1) == "unknown"
        end
    end
end
