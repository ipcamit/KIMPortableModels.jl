# Model Management

Low-level model creation and management functions for advanced users.

## Types

```@docs
Model
ComputeArguments
```

## Model Creation

```@docs
create_model
destroy_model!
```

## Compute Arguments

```@docs
create_compute_arguments
destroy_compute_arguments!
set_argument_pointer!
```

## Model Properties

```@docs
get_influence_distance
get_neighbor_list_pointers
get_argument_support_status
```

## Computation

```@docs
compute!
set_callback_pointer!
```

## Usage Example

```julia
using kim_api

# Create model with specific units
model, accepted = create_model(
    zeroBased, A, eV, e, K, ps,
    "SW_StillingerWeber_1985_Si__MO_405512056662_006"
)

if !accepted
    error("Model rejected the specified units")
end

# Create compute arguments
args = create_compute_arguments(model)

# Check what properties are supported
energy_support = get_argument_support_status(args, partialEnergy)
forces_support = get_argument_support_status(args, partialForces)

println("Energy support: ", energy_support)
println("Forces support: ", forces_support)

# Get neighbor list requirements
n_lists, cutoffs, will_not_request = get_neighbor_list_pointers(model)
println("Model requires ", n_lists, " neighbor lists with cutoffs: ", cutoffs)

# Set up data pointers
n_particles = length(species)
species_codes = get_species_codes_from_model(model, species)

set_argument_pointer!(args, numberOfParticles, Ref{Cint}(n_particles))
set_argument_pointer!(args, particleSpeciesCodes, species_codes)
set_argument_pointer!(args, coordinates, positions_matrix)
set_argument_pointer!(args, particleContributing, contributing_flags)

# Set up output arrays
energy = Ref{Cdouble}(0.0)
forces = zeros(Cdouble, 3, n_particles)

set_argument_pointer!(args, partialEnergy, energy)
set_argument_pointer!(args, partialForces, forces)

# Set neighbor list callback (if needed)
# ... callback setup ...

# Perform calculation
compute!(model, args)

println("Computed energy: ", energy[])
println("Computed forces: ", forces)

# Cleanup
destroy_compute_arguments!(model, args)
destroy_model!(model)
```

## Memory Management

The low-level interface requires careful memory management:

1. **Always destroy** created objects when done
2. **Keep references** to arrays passed to `set_argument_pointer!`
3. **Use `GC.@preserve`** during computation to prevent garbage collection
4. **Check return codes** for all operations

```julia
# Proper memory management pattern
model, accepted = create_model(...)
try
    args = create_compute_arguments(model)
    try
        # ... set up pointers and compute ...
        GC.@preserve species_codes positions forces energy begin
            compute!(model, args)
        end
    finally
        destroy_compute_arguments!(model, args)
    end
finally
    destroy_model!(model)
end
```