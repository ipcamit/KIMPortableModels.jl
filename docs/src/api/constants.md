# Constants & Units

This page documents the constants, enumerations, and unit systems provided by KIMPortableModels.jl.

## Enumerations

The following enumerations are defined and exported from KIMPortableModels.jl:

- `Numbering`: Zero-based or one-based indexing
- `LengthUnit`: Length units (angstrom, meter, etc.)
- `EnergyUnit`: Energy units (eV, Joule, etc.)
- `ChargeUnit`: Charge units (electron charge, Coulomb, etc.)
- `TemperatureUnit`: Temperature units (Kelvin)
- `TimeUnit`: Time units (second, femtosecond, etc.)
- `ComputeArgumentName`: KIM-API compute argument names
- `ComputeCallbackName`: KIM-API callback function names
- `LanguageName`: Programming language identifiers
- `SupportStatus`: Support status for model features

## Unit Systems

The package provides several predefined unit systems through `UNIT_STYLES` and the `get_lammps_style_units()` function:

- `:metal`: Ångström, eV, electron charge, Kelvin, picosecond (LAMMPS metal units)
- `:real`: Ångström, kcal/mol, electron charge, Kelvin, femtosecond (LAMMPS real units)
- `:si`: meter, Joule, Coulomb, Kelvin, second (SI units)
- `:cgs`: centimeter, erg, statCoulomb, Kelvin, second (CGS units)
- `:electron`: Bohr, Hartree, electron charge, Kelvin, femtosecond (atomic units)

Use `get_lammps_style_units(:metal)` to get the tuple of units for a given style.

## Constant Lookup Functions

```@docs
get_numbering
get_length_unit
get_energy_unit
get_charge_unit
get_temperature_unit
get_time_unit
get_compute_argument_name
get_compute_callback_name
get_language_name
get_support_status
```

## String Conversion Functions

```@docs
numbering_to_string
length_unit_to_string
energy_unit_to_string
compute_argument_name_to_string
```