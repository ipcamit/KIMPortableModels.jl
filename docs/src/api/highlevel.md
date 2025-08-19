# High-level Interface

The high-level interface provides a simple, Julia-friendly way to use KIM-API models without dealing with the underlying C API complexity.

```@docs
kim_api.KIMModel
```

## Usage Examples

### Basic Usage

```julia
using kim_api

# Create model for silicon
model = kim_api.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")

# Simple two-atom system
species = ["Si", "Si"] 
positions = [SVector(0.0, 0.0, 0.0), SVector(2.7, 2.7, 2.7)]
cell = 5.43 * I(3)
pbc = [true, true, true]

# Compute properties
results = model(species, positions, cell, pbc)
```

### Different Unit Systems

```julia
# Use LAMMPS real units (Å, kcal/mol, fs)
model_real = kim_api.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006", 
                      units=:real)

# Use SI units (m, J, s)  
model_si = kim_api.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006",
                    units=:si)

# Custom units
model_custom = kim_api.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006",
                        units=(A, eV, e, K, ps))
```

### Energy-only Calculations

```julia
# Only compute energy (faster for some applications)
model_energy = kim_api.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006",
                        compute=[:energy])

results = model_energy(species, positions, cell, pbc)
# results[:forces] will not be available
```

## Function Signature

The function returned by `KIMModel()` has the signature:

```julia
f(species, positions, cell, pbc) -> Dict{Symbol, Any}
```

### Parameters

- **`species::Vector{String}`**: Chemical symbols for each atom (e.g., `["Si", "C", "O"]`)
- **`positions::Vector{SVector{3,Float64}}`**: Atomic coordinates as 3D vectors
- **`cell::Matrix{Float64}`**: Unit cell matrix (3×3, column vectors are lattice vectors)
- **`pbc::Vector{Bool}`**: Periodic boundary conditions `[x, y, z]`

### Returns

Dictionary with computed properties:
- **`:energy`**: Total potential energy (scalar)
- **`:forces`**: Forces on each atom (3×N matrix)

The exact keys present depend on the `compute` argument passed to `KIMModel()`.

## Error Handling

The high-level interface provides informative error messages:

```julia
# Model doesn't exist
try
    model = KIMModel("NonExistentModel")
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

## Performance Tips

1. **Reuse the model function**: Create once, call many times
2. **Pre-allocate positions**: Use consistent array types
3. **Batch calculations**: Process multiple configurations efficiently
4. **Choose appropriate units**: Avoid unnecessary conversions

```julia
# Good: create once, use many times
model = KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")

energies = Float64[]
for config in configurations
    results = model(species, config.positions, config.cell, pbc)
    push!(energies, results[:energy])
end
```