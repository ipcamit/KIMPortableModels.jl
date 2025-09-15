# test_constants.jl - Test KIM constants
using Test

# Include the constants file (adjust path as needed)
include("../src/constants.jl")

# Set libkim path for tests
const libkim = get(ENV, "KIM_LIBRARY_PATH", "/opt/KIM/install/lib/libkim-api")

@testset "KIM Constants Tests" begin

    @testset "Enum Values" begin
        # Test enum integer values
        @test Int(zeroBased) == 0
        @test Int(oneBased) == 1

        @test Int(A) == 1
        @test Int(eV) == 3
        @test Int(numberOfParticles) == 0
        @test Int(GetNeighborList) == 0
        @test Int(c) == 1
        @test Int(required) == 2
    end

    @testset "String to Constant Functions" begin
        # Test get_* functions match enum values
        @test get_numbering("zeroBased") == Int(zeroBased)
        @test get_numbering("oneBased") == Int(oneBased)

        @test get_length_unit("A") == Int(A)
        @test get_length_unit("Bohr") == Int(Bohr)
        @test get_length_unit("m") == Int(m)

        @test get_energy_unit("eV") == Int(eV)
        @test get_energy_unit("kcal_mol") == Int(kcal_mol)
        @test get_energy_unit("J") == Int(J)

        @test get_charge_unit("e") == Int(e)
        @test get_charge_unit("C") == Int(C)

        @test get_temperature_unit("K") == Int(K)

        @test get_time_unit("ps") == Int(ps)
        @test get_time_unit("fs") == Int(fs)

        @test get_compute_argument_name("numberOfParticles") == Int(numberOfParticles)
        @test get_compute_argument_name("coordinates") == Int(coordinates)
        @test get_compute_argument_name("partialForces") == Int(partialForces)

        @test get_compute_callback_name("GetNeighborList") == Int(GetNeighborList)

        @test get_language_name("c") == Int(c)
        @test get_language_name("cpp") == Int(cpp)

        @test get_support_status("required") == Int(required)
        @test get_support_status("optional") == Int(optional)
    end

    @testset "Constant to String Functions" begin
        # Test reverse lookup functions
        @test numbering_to_string(0) == "zeroBased"
        @test numbering_to_string(1) == "oneBased"
        @test numbering_to_string(Int(zeroBased)) == "zeroBased"  # Test with enum

        @test length_unit_to_string(1) == "A"
        @test length_unit_to_string(2) == "Bohr"
        @test length_unit_to_string(Int(A)) == "A"  # Test with enum

        @test energy_unit_to_string(3) == "eV"
        @test energy_unit_to_string(6) == "kcal_mol"
        @test energy_unit_to_string(Int(eV)) == "eV"  # Test with enum

        @test compute_argument_name_to_string(0) == "numberOfParticles"
        @test compute_argument_name_to_string(3) == "coordinates"
        @test compute_argument_name_to_string(Int(numberOfParticles)) == "numberOfParticles"  # Test with enum

        # Test invalid values
        @test numbering_to_string(999) == "unknown"
        @test length_unit_to_string(-1) == "unknown"
    end

    @testset "Unit Styles" begin
        # Test metal units
        metal = UNIT_STYLES.metal
        @test metal.numbering == zeroBased
        @test metal.length == A
        @test metal.energy == eV
        @test metal.charge == e
        @test metal.temperature == K
        @test metal.time == ps

        # Test real units
        real = UNIT_STYLES.real
        @test real.energy == kcal_mol
        @test real.time == fs

        # Test SI units
        si = UNIT_STYLES.si
        @test si.length == m
        @test si.energy == J
        @test si.charge == C
        @test si.time == s
    end

    @testset "Enum Conversions" begin
        # String to enum
        @test LengthUnit(1) == A
        @test EnergyUnit(3) == eV

        # Enum to string
        @test string(A) == "A"
        @test string(eV) == "eV"
        @test string(numberOfParticles) == "numberOfParticles"

        # Integer to enum
        @test LengthUnit(1) == A
        @test EnergyUnit(3) == eV
        @test ComputeArgumentName(0) == numberOfParticles

        # Enum to integer
        @test Int(A) == 1
        @test Int(eV) == 3
        @test Int(numberOfParticles) == 0
    end

    @testset "Round-trip Conversions" begin
        # Test string -> constant -> string
        for unit in ["A", "Bohr", "cm", "m", "nm"]
            val = get_length_unit(unit)
            @test length_unit_to_string(val) == unit
        end

        for unit in ["eV", "J", "kcal_mol", "erg", "Hartree"]
            val = get_energy_unit(unit)
            @test energy_unit_to_string(val) == unit
        end

        # Test enum -> string -> constant
        for enum_val in instances(LengthUnit)
            str = string(enum_val)
            @test get_length_unit(str) == Int(enum_val)
        end
    end

    @testset "Error Handling" begin
        # Test invalid enum conversions
        @test_throws MethodError parse(LengthUnit, "invalid")
        @test_throws MethodError parse(EnergyUnit, "invalid")

        # Test invalid integer to enum
        @test_throws ArgumentError LengthUnit(999)
        @test_throws ArgumentError EnergyUnit(-1)
    end

    @testset "Species Names" begin
        # Test common species
        si_code = get_species_name("Si")
        ar_code = get_species_name("Ar")

        @test si_code >= 0  # Valid species should return non-negative
        @test ar_code >= 0
    end
end

# Run tests
println("Running KIM constants tests...")
#@time @testset "All Tests" begin
#    include(@__FILE__)
#end
