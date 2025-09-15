# Examples

This page provides practical examples of using KIM.jl for various molecular simulation tasks.

## Basic Examples

### Computing Energy and Forces

```julia
using KIM
using StaticArrays
using LinearAlgebra

# Create a KIM model for silicon
model = KIM.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")

# Define a silicon dimer
species = ["Si", "Si"]
positions = [
    SVector(0.0, 0.0, 0.0),     # First silicon atom
    SVector(2.35, 0.0, 0.0)     # Second silicon atom at equilibrium distance
]

# Set up periodic cell (large enough to avoid self-interaction)
cell = 10.0 * I(3)  # 10×10×10 Å cubic cell
pbc = [true, true, true]

# Compute properties
results = model(species, positions, cell, pbc)

println("Energy: $(results[:energy]) eV")
println("Force on atom 1: $(results[:forces][:, 1]) eV/Å")
println("Force on atom 2: $(results[:forces][:, 2]) eV/Å")
```

### Energy Minimization

```julia
using KIM, Optim
using StaticArrays, LinearAlgebra

# Set up model and initial structure
model = KIM.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")
species = ["Si", "Si"]
cell = [5.43 0.0 0.0; 0.0 5.43 0.0; 0.0 0.0 5.43]
pbc = [true, true, true]

# Objective function for optimization
function objective(x)
    pos = [SVector(0.0, 0.0, 0.0), SVector(x[1], x[2], x[3])]
    results = model(species, pos, cell, pbc)
    return results[:energy]
end

# Optimize second atom position
initial_pos = [2.5, 0.0, 0.0]  # Starting guess
result = result = optimize(objective, initial_pos, BFGS(), Optim.Options(f_tol=1e-4))

println("Optimized position: ", result.minimizer)
println("Minimum energy: ", result.minimum)
```

