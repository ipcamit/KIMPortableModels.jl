# High-level Interface

The high-level interface provides a simple, Julia-friendly way to use KIM-API models without dealing with the underlying C API complexity.

## Core Functions

```@docs
KIMPortableModels.KIMModel
KIMPortableModels.KIMCalculator
```

## Usage Examples

### Basic Usage with KIMModel

```julia
using KIMPortableModels, StaticArrays, LinearAlgebra

# Create model for silicon
model = KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")

# Simple two-atom system
species = ["Si", "Si"]
positions = [SVector(0.0, 0.0, 0.0), SVector(2.35, 0.0, 0.0)]
cell = Matrix(5.43 * I(3))
pbc = [true, true, true]

# Compute properties
results = model(species, positions, cell, pbc)
println("Energy: $(results[:energy]) eV")
println("Forces: $(results[:forces])")
```

### AtomsCalculators Interface with KIMCalculator

```julia
using KIMPortableModels, AtomsBase, AtomsCalculators

# Create a KIM calculator
calc = KIMCalculator("SW_StillingerWeber_1985_Si__MO_405512056662_006")

# Create AtomsBase system
particles = [
    :Si => SVector(0.0u"Å", 0.0u"Å", 0.0u"Å"),
    :Si => SVector(2.35u"Å", 0.0u"Å", 0.0u"Å")
]
cell_vectors = (
    SVector(5.43u"Å", 0.0u"Å", 0.0u"Å"),
    SVector(0.0u"Å", 5.43u"Å", 0.0u"Å"),
    SVector(0.0u"Å", 0.0u"Å", 5.43u"Å")
)
system = FlexibleSystem(particles; cell_vectors=cell_vectors, periodicity=(true, true, true))

# Use AtomsCalculators interface
energy = AtomsCalculators.potential_energy(calc, system)
forces = AtomsCalculators.forces(calc, system)

# Or call calculator directly
results = calc(system)
```

### Different Unit Systems

```julia
# Use LAMMPS real units (Å, kcal/mol, fs)
calc_real = KIMCalculator("SW_StillingerWeber_1985_Si__MO_405512056662_006", units=:real)

# Use SI units (m, J, s)
calc_si = KIMCalculator("SW_StillingerWeber_1985_Si__MO_405512056662_006", units=:si)

# Compare energies in different units
energy_metal = AtomsCalculators.potential_energy(calc, system)  # eV
energy_real = AtomsCalculators.potential_energy(calc_real, system)  # kcal/mol
```

### Energy-only Calculations

```julia
# Only compute energy (faster for some applications)
calc_energy = KIMCalculator("SW_StillingerWeber_1985_Si__MO_405512056662_006", compute=[:energy])

# This will only compute energy, not forces
energy = AtomsCalculators.potential_energy(calc_energy, system)

# Or with raw arrays
model_energy = KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006", compute=[:energy])
results = model_energy(species, positions, cell, pbc)
# results[:forces] will not be available
```

### Equivalence Between Methods

```julia
# Both methods give identical results
raw_result = model(species, positions, cell, pbc)
atomsbase_result = calc(system)

@assert raw_result[:energy] ≈ atomsbase_result[:energy]
@assert raw_result[:forces] ≈ atomsbase_result[:forces]
```

## Interface Details

### KIMModel Function Signature

The function returned by `KIMModel()` has the signature:

```julia
f(species, positions, cell, pbc) -> Dict{Symbol, Any}
```

**Parameters:**
- **`species::Vector{String}`**: Chemical symbols for each atom (e.g., `["Si", "C", "O"]`)
- **`positions::Vector{SVector{3,Float64}}`**: Atomic coordinates as 3D vectors
- **`cell::Matrix{Float64}`**: Unit cell matrix (3×3, column vectors are lattice vectors)
- **`pbc::Vector{Bool}`**: Periodic boundary conditions `[x, y, z]`

**Returns:**
Dictionary with computed properties:
- **`:energy`**: Total potential energy (scalar)
- **`:forces`**: Forces on each atom (3×N matrix)

### KIMCalculator Interface

`KIMCalculator` implements the `AtomsCalculators.AbstractCalculator` interface:

```julia
# Direct calculation (returns all computed properties)
calc(system::AtomsBase.AbstractSystem) -> Dict{Symbol, Any}

# AtomsCalculators interface
AtomsCalculators.potential_energy(calc, system) -> Float64
AtomsCalculators.forces(calc, system) -> Matrix{Float64}
```

**Supported Systems:**
- Any `AtomsBase.AbstractSystem` (e.g., `FlexibleSystem`)
- Automatic unit handling with `Unitful.jl`
- Supports both periodic and non-periodic systems

**Internal Conversion:**
- Extracts species symbols, positions, cell vectors, and boundary conditions
- Strips units automatically (converts to base units)
- Calls underlying `KIMModel` function

## Error Handling

The high-level interface provides informative error messages:

```julia
# Model doesn't exist
try
    model = KIMPortableModels.KIMModel("NonExistentModel")
catch e
    println("Model creation failed: ", e)
end

# Unsupported species
try
    results = model(["Unobtainium"], positions, cell, pbc)
catch e
    println("Species error: ", e)
end
```

