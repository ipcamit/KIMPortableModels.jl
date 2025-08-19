# test_constants.jl - Test KIM constants and enumerations

@testset "Constants and Enumerations" begin
    
    @testset "Enumeration Values" begin
        # Test that enums have correct integer values (matching KIM-API C constants)
        @test Int(kim_api.zeroBased) == 0
        @test Int(kim_api.oneBased) == 1
        
        @test Int(kim_api.A) == 1
        @test Int(kim_api.Bohr) == 2
        @test Int(kim_api.eV) == 3
        @test Int(kim_api.e) == 2
        @test Int(kim_api.K) == 1
        @test Int(kim_api.ps) == 2
        
        @test Int(kim_api.numberOfParticles) == 0
        @test Int(kim_api.particleSpeciesCodes) == 1
        @test Int(kim_api.coordinates) == 3
        @test Int(kim_api.partialEnergy) == 4
        @test Int(kim_api.partialForces) == 5
        
        @test Int(kim_api.GetNeighborList) == 0
        @test Int(kim_api.c) == 1
        @test Int(kim_api.required) == 2
        @test Int(kim_api.optional) == 3
        @test Int(kim_api.notSupported) == 1
    end
    
    @testset "Unit Styles" begin
        # Test predefined unit styles
        metal = kim_api.UNIT_STYLES.metal
        @test metal.length == kim_api.A
        @test metal.energy == kim_api.eV
        @test metal.charge == kim_api.e
        @test metal.temperature == kim_api.K
        @test metal.time == kim_api.ps
        
        real = kim_api.UNIT_STYLES.real
        @test real.length == kim_api.A
        @test real.energy == kim_api.kcal_mol
        @test real.time == kim_api.fs
        
        si = kim_api.UNIT_STYLES.si
        @test si.length == kim_api.m
        @test si.energy == kim_api.J
        @test si.charge == kim_api.C
        @test si.time == kim_api.s
        
        electron = kim_api.UNIT_STYLES.electron
        @test electron.length == kim_api.Bohr
        @test electron.energy == kim_api.Hartree
        @test electron.time == kim_api.fs
    end
    
    @testset "Unit Style Function" begin
        # Test get_lammps_style_units function
        metal_units = kim_api.get_lammps_style_units(:metal)
        @test metal_units.length == kim_api.A
        @test metal_units.energy == kim_api.eV
        
        real_units = kim_api.get_lammps_style_units(:real)
        @test real_units.energy == kim_api.kcal_mol
        
        si_units = kim_api.get_lammps_style_units(:si)
        @test si_units.length == kim_api.m
        @test si_units.energy == kim_api.J
        
        # Test error for invalid style
        @test_throws ErrorException kim_api.get_lammps_style_units(:invalid)
    end
    
    if isdefined(kim_api, :libkim) && kim_api.libkim != ""
        @testset "KIM-API Constant Functions" begin
            # Test constant lookup functions (require KIM-API library)
            @test kim_api.get_numbering("zeroBased") == 0
            @test kim_api.get_numbering("oneBased") == 1
            
            @test kim_api.get_length_unit("A") == 1
            @test kim_api.get_length_unit("Bohr") == 2
            
            @test kim_api.get_energy_unit("eV") == 3
            @test kim_api.get_energy_unit("J") == 5
            
            @test kim_api.get_charge_unit("e") == 2
            @test kim_api.get_charge_unit("C") == 1
            
            @test kim_api.get_temperature_unit("K") == 1
            
            @test kim_api.get_time_unit("fs") == 1
            @test kim_api.get_time_unit("ps") == 2
        end
        
        @testset "Reverse Lookup Functions" begin
            # Test constant to string conversion
            @test kim_api.numbering_to_string(0) == "zeroBased"
            @test kim_api.numbering_to_string(1) == "oneBased"
            
            @test kim_api.length_unit_to_string(1) == "A"
            @test kim_api.length_unit_to_string(2) == "Bohr"
            
            @test kim_api.energy_unit_to_string(3) == "eV"
            @test kim_api.energy_unit_to_string(5) == "J"
            
            # Test unknown values
            @test kim_api.numbering_to_string(999) == "unknown"
            @test kim_api.length_unit_to_string(-1) == "unknown"
        end
    end
end