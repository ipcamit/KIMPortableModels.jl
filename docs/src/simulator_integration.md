# Adding KIM Support to Your Simulator

This guide provides step-by-step instructions for integrating KIMPortableModels.jl into your Julia-based molecular dynamics simulator or computational physics code.

## Overview

KIMPortableModels.jl provides a high-level interface that makes it easy to add support for hundreds of validated interatomic models to your simulator. The integration requires minimal code changes and follows Julia best practices.

## Quick Integration Steps

### 1. Basic Integration Pattern Using highlevel functions provided by KIMPortableModels.jl

Here's the minimal code pattern for adding KIM model support to your simulator:

```julia
using KIMPortableModels
using StaticArrays
using LinearAlgebra

# Your simulator's main computation function
function simulate_system(positions, species, cell, pbc, model_name; timesteps=1000, dt=0.001)

    # Initialize KIM model (do this once)
    kim_model = KIMPortableModels.KIMModel(model_name)

    # Your simulation loop
    for step in 1:timesteps
        # Compute forces and energy using KIM model
        results = kim_model(species, positions, cell, pbc)

        energy = results[:energy]
        forces = results[:forces]  # 3×N matrix of forces

        # Integrate equations of motion (your existing code)
        positions, velocities = integrate_motion(positions, velocities, forces, dt)

        # Your analysis/output code here
        if step % 100 == 0
            println("Step $step: Energy = $energy")
        end
    end

    return positions, velocities
end
```

### 2. Data Format Requirements

Your simulator needs to provide data in the following formats:

#### Required Inputs
- **`species`**: `Vector{String}` - Chemical symbols (e.g., `["Si", "Si", "O"]`)
- **`positions`**: `Vector{SVector{3,Float64}}` - Atomic positions in Cartesian coordinates
- **`cell`**: `Matrix{Float64}` - 3×3 unit cell matrix (columns are lattice vectors)
- **`pbc`**: `Vector{Bool}` - Periodic boundary conditions `[x, y, z]`

#### Outputs
- **`results[:energy]`**: `Float64` - Total potential energy
- **`results[:forces]`**: `Matrix{Float64}` - 3×N matrix of forces on each atom


## Advanced Integration

For more performant/fine-grained control, you can use the low-level API directly instead of the high-level `KIMModel` function.

### Low-Level API Usage

Here's how to initialize and use KIM models directly with the low-level interface:

```julia
using KIMPortableModels

# 1. Create model with specific units
model, accepted = KIMPortableModels.create_model(
    KIMPortableModels.zeroBased,  # Use 0-based indexing
    KIMPortableModels.A,          # Angstrom
    KIMPortableModels.eV,         # Electron volt
    KIMPortableModels.e,          # Elementary charge
    KIMPortableModels.K,          # Kelvin
    KIMPortableModels.ps,         # Picosecond
    "SW_StillingerWeber_1985_Si__MO_405512056662_006"
)

if !accepted
    error("Units not accepted by model")
end

# 2. Create compute arguments
args = KIMPortableModels.create_compute_arguments(model)

# 3. Check what the model supports
energy_support = KIMPortableModels.get_argument_support_status(args, KIMPortableModels.partialEnergy)
forces_support = KIMPortableModels.get_argument_support_status(args, KIMPortableModels.partialForces)

# 4. Set up data arrays
n_atoms = 2
coords = [0.0 2.0; 0.0 0.0; 0.0 0.0]  # 3×N matrix
species_codes = Int32[14, 14]  # Silicon atoms (atomic number 14)
contributing = ones(Int32, n_atoms)  # All atoms contribute to energy
n_ref = Ref{Int32}(n_atoms)
energy_ref = Ref{Float64}(0.0)
forces = zeros(Float64, 3, n_atoms)

# 5. Set argument pointers
KIMPortableModels.set_argument_pointer!(args, KIMPortableModels.numberOfParticles, n_ref)
KIMPortableModels.set_argument_pointer!(args, KIMPortableModels.particleSpeciesCodes, species_codes)
KIMPortableModels.set_argument_pointer!(args, KIMPortableModels.coordinates, coords)
KIMPortableModels.set_argument_pointer!(args, KIMPortableModels.particleContributing, contributing)
KIMPortableModels.set_argument_pointer!(args, KIMPortableModels.partialEnergy, energy_ref)
KIMPortableModels.set_argument_pointer!(args, KIMPortableModels.partialForces, forces)

# 6. Compute energy and forces
KIMPortableModels.compute!(model, args)

println("Energy: $(energy_ref[]) eV")
println("Forces: $forces")

# 7. Clean up (optional - handled by finalizers)
KIMPortableModels.destroy_compute_arguments!(model, args)
KIMPortableModels.destroy_model!(model)
```

### Neighbor Lists

KIM models that require neighbor lists need special handling. Here's how to set up neighbor list callbacks:

```julia
# Get neighbor list requirements from model
n_cutoffs, cutoffs, will_not_request = KIMPortableModels.get_neighbor_list_pointers(model)

if n_cutoffs > 0
    println("Model requires $n_cutoffs neighbor lists with cutoffs: $cutoffs")

    # Create neighbor lists using KIMNeighborList.jl
    nl_handle, all_coords, all_species, contributing, atom_indices =
        KIMPortableModels.create_kim_neighborlists(
            species, positions, cell, pbc, cutoffs;
            will_not_request_ghost_neigh = will_not_request
        )

    # Set up neighbor list callback
    GC.@preserve nl_handle all_coords begin
        callback_ptr = @cast_as_kim_neigh_fptr(KIMPortableModels.kim_neighbors_callback)
        data_ptr = pointer_from_objref(nl_handle)
        KIMPortableModels.set_callback_pointer!(args, KIMPortableModels.GetNeighborList,
                                               KIMPortableModels.c, callback_ptr, data_ptr)

        # Now compute with neighbor lists
        KIMPortableModels.compute!(model, args)
    end
end
```

### Performance Tips

- **Model Reuse**: Create models once and reuse them
- **Memory Layout**: Use column-major layout for coordinates (3×N matrix)
- **Species Codes**: Pre-compute species codes using `get_species_number("Si")`
- **Energy-Only**: Skip force calculation setup if only energy is needed


## Finding and Using KIM Models

Browse available models at [openkim.org](https://openkim.org) or use the KIM-API tools:

```bash
# List installed models
kim-api-collections-management list

# Install a specific model
kim-api-collections-management install user SW_StillingerWeber_1985_Si__MO_405512056662_006
```

## Detailed Implementation Guide

For a comprehensive, step-by-step guide with more detailed examples and advanced topics, see the blog post:

**[Through the Looking Glass: Implementing KIM-API for Your Molecular Dynamics Simulator](https://ipcamit.github.io/through-the-looking-glass-implementing-kim-api-for-your-molecular-dynamics-simulator/)**

This blog covers:
- Detailed KIM-API concepts and architecture
- Advanced neighbor list handling
- Performance optimization strategies
- Debugging and troubleshooting tips
- Real-world integration examples

