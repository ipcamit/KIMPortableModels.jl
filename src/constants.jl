# constants.jl - KIM-API constants

# Enumerations matching KIM-API values
@enum Numbering::Cint begin
    zeroBased = 0
    oneBased = 1
end

@enum LengthUnit::Cint begin
    A = 1
    Bohr = 2
    cm = 3
    m = 4
    nm = 5
end

@enum EnergyUnit::Cint begin
    amu_A2_per_ps2 = 1
    erg = 2
    eV = 3
    Hartree = 4
    J = 5
    kcal_mol = 6
end

@enum ChargeUnit::Cint begin
    C = 1
    e = 2
    statC = 3
end

@enum TemperatureUnit::Cint begin
    K = 1
end

@enum TimeUnit::Cint begin
    fs = 1
    ps = 2
    ns = 3
    s = 4
end

@enum ComputeArgumentName::Cint begin
    numberOfParticles = 0
    particleSpeciesCodes = 1
    particleContributing = 2
    coordinates = 3
    partialEnergy = 4
    partialForces = 5
    partialParticleEnergy = 6
    partialVirial = 7
    partialParticleVirial = 8
end

@enum ComputeCallbackName::Cint begin
    GetNeighborList = 0
    ProcessDEDrTerm = 1
    ProcessD2EDr2Term = 2
end

@enum LanguageName::Cint begin
    cpp = 0
    c = 1
    fortran = 2
end

@enum SupportStatus::Cint begin
    notSupported = 1
    required = 2
    optional = 3
end

# Unit style combinations
const UNIT_STYLES = (
    metal = (numbering=zeroBased, length=A, energy=eV, charge=e, temperature=K, time=ps),
    real = (numbering=zeroBased, length=A, energy=kcal_mol, charge=e, temperature=K, time=fs),
    si = (numbering=zeroBased, length=m, energy=J, charge=C, temperature=K, time=s),
    cgs = (numbering=zeroBased, length=cm, energy=erg, charge=statC, temperature=K, time=s),
    electron = (numbering=zeroBased, length=Bohr, energy=Hartree, charge=e, temperature=K, time=fs)
)

##############################################################################################
# Lookup functions to get constants from strings and vice versa
###############################################################################################

"""
    get_numbering(name::String) -> Cint

Get numbering constant from string name ("zeroBased" or "oneBased")
"""
function get_numbering(name::String)
    @ccall libkim.KIM_Numbering_FromString(name::Cstring)::Cint
end

"""
    get_length_unit(name::String) -> Cint

Get length unit constant from string name ("A", "Bohr", "cm", "m", "nm")
"""
function get_length_unit(name::String)
    @ccall libkim.KIM_LengthUnit_FromString(name::Cstring)::Cint
end

"""
    get_energy_unit(name::String) -> Cint

Get energy unit constant from string name ("eV", "J", "kcal_mol", etc.)
"""
function get_energy_unit(name::String)
    @ccall libkim.KIM_EnergyUnit_FromString(name::Cstring)::Cint
end

"""
    get_charge_unit(name::String) -> Cint

Get charge unit constant from string name ("C", "e")
"""
function get_charge_unit(name::String)
    @ccall libkim.KIM_ChargeUnit_FromString(name::Cstring)::Cint
end

"""
    get_temperature_unit(name::String) -> Cint

Get temperature unit constant from string name ("K")
"""
function get_temperature_unit(name::String)
    @ccall libkim.KIM_TemperatureUnit_FromString(name::Cstring)::Cint
end

"""
    get_time_unit(name::String) -> Cint

Get time unit constant from string name ("fs", "ps", "ns", "s")
"""
function get_time_unit(name::String)
    @ccall libkim.KIM_TimeUnit_FromString(name::Cstring)::Cint
end

"""
    get_compute_argument_name(name::String) -> Cint

Get compute argument name constant from string
"""
function get_compute_argument_name(name::String)
    @ccall libkim.KIM_ComputeArgumentName_FromString(name::Cstring)::Cint
end

"""
    get_compute_callback_name(name::String) -> Cint

Get compute callback name constant from string
"""
function get_compute_callback_name(name::String)
    @ccall libkim.KIM_ComputeCallbackName_FromString(name::Cstring)::Cint
end

"""
    get_language_name(name::String) -> Cint

Get language name constant from string ("c", "cpp", "fortran")
"""
function get_language_name(name::String)
    @ccall libkim.KIM_LanguageName_FromString(name::Cstring)::Cint
end

"""
    get_support_status(name::String) -> Cint

Get support status constant from string ("required", "optional", "notSupported")
"""
function get_support_status(name::String)
    @ccall libkim.KIM_SupportStatus_FromString(name::Cstring)::Cint
end

"""
    get_species_name(name::String) -> Cint

Get species name constant from string (e.g., "Ar", "Si", etc.)
"""
function get_species_name(name::String)
    @ccall libkim.KIM_SpeciesName_FromString(name::Cstring)::Cint
end


# Reverse lookup functions (get string from integer)
"""
    numbering_to_string(value::Cint) -> String

Convert numbering integer to string
"""
function numbering_to_string(value::Integer)
    ptr = @ccall libkim.KIM_Numbering_ToString(Cint(value)::Cint)::Ptr{Cchar}
    ptr == C_NULL ? "unknown" : unsafe_string(ptr)
end

"""
    length_unit_to_string(value::Cint) -> String

Convert length unit integer to string
"""
function length_unit_to_string(value::Integer)
    ptr = @ccall libkim.KIM_LengthUnit_ToString(Cint(value)::Cint)::Ptr{Cchar}
    ptr == C_NULL ? "unknown" : unsafe_string(ptr)
end

"""
    energy_unit_to_string(value::Cint) -> String

Convert energy unit integer to string
"""
function energy_unit_to_string(value::Integer)
    ptr = @ccall libkim.KIM_EnergyUnit_ToString(Cint(value)::Cint)::Ptr{Cchar}
    ptr == C_NULL ? "unknown" : unsafe_string(ptr)
end

"""
    compute_argument_name_to_string(value::Cint) -> String

Convert compute argument name integer to string
"""
function compute_argument_name_to_string(value::Integer)
    ptr = @ccall libkim.KIM_ComputeArgumentName_ToString(Cint(value)::Cint)::Ptr{Cchar}
    ptr == C_NULL ? "unknown" : unsafe_string(ptr)
end

# Export all structures
export Numbering, LengthUnit, EnergyUnit, ChargeUnit,
       TemperatureUnit, TimeUnit, ComputeArgumentName,
       ComputeCallbackName, LanguageName, SupportStatus,
        UNIT_STYLES

# Export all functions
export get_numbering, get_length_unit, get_energy_unit, get_charge_unit,
       get_temperature_unit, get_time_unit, get_compute_argument_name,
       get_compute_callback_name, get_language_name, get_support_status,
       get_species_name,
       numbering_to_string, length_unit_to_string, energy_unit_to_string,
       compute_argument_name_to_string
