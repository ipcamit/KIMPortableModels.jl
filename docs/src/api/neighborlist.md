# Neighbor Lists

Neighbor list implementation and callback functions for KIM-API.

## Types

```@docs
KIM.NeighborListContainer
```

## Functions

```@docs
KIM.create_kim_neighborlists
KIM.kim_neighbors_callback
```

## Macros

```@docs
KIM.@cast_as_kim_neigh_fptr
```

## Implementation Details

The neighbor list system in KIM.jl handles several complex aspects of KIM-API integration:

### Periodic Boundary Conditions

When periodic boundary conditions are enabled, the system automatically creates ghost atoms:

```julia
# Original atoms at positions
positions = [SVector(0.0, 0.0, 0.0), SVector(4.8, 0.0, 0.0)]

# With PBC, ghost atoms are created for neighbors across boundaries
containers, all_positions, all_species, contributing, atom_indices = 
    create_kim_neighborlists(positions, [3.0], cell, [true, true, true])

# all_positions now includes both real atoms and their periodic images
# contributing flags: 1 for real atoms, 0 for ghost atoms
```

### Multiple Cutoffs

Some KIM models require multiple neighbor lists with different cutoff distances:

```julia
# Model requires two neighbor lists
cutoffs = [2.5, 3.5]  # Two different cutoff distances

containers, ... = create_kim_neighborlists(positions, cutoffs, cell, pbc)
# Returns one container per cutoff distance
```

### Index Conversion

The callback system handles conversion between Julia's 1-based and KIM-API's 0-based indexing:

- Julia uses 1-based indexing internally
- KIM-API expects 0-based indexing
- The callback function performs automatic conversion

### Callback Function Signature

The neighbor callback must match this exact C signature:

```c
int callback(void* data_object, int number_of_neighbor_lists, 
            double* cutoffs, int neighbor_list_index, int particle_number,
            int* number_of_neighbors, int** neighbors_list_pointer)
```

You can cast this into expected function pointer using `KIM.cast_as_kim_neigh_fptr`.

### Memory Management

The neighbor list containers maintain persistent storage to ensure:

- Neighbor arrays remain valid after callback returns
- No memory allocations during callback execution
- Proper cleanup when containers are garbage collected

## Usage Examples

### Basic Usage

```julia
using KIM, StaticArrays

# Define atomic positions
positions = [SVector(0.0, 0.0, 0.0), SVector(2.5, 0.0, 0.0)]
species = ["Si", "Si"]
cell = Matrix(5.0 * I(3))
pbc = [true, true, true]

# Create neighbor lists for 3.0 Å cutoff
containers, all_pos, all_spec, contrib, indices = 
    create_kim_neighborlists(positions, [3.0], species, 
                           cell=cell, pbc=pbc)
```

### With KIM Model

```julia
# The high-level interface handles this automatically
model = KIM.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")
results = model(species, positions, cell, pbc)
# Neighbor lists are created and managed internally
```

### Custom Neighbor Functions

For advanced users who need custom neighbor list implementations:

```julia
# Create your own neighbor function
function my_neighbor_function(positions, cutoff, cell, pbc)
    # Custom neighbor finding algorithm
    # Must return neighbors in 1-based Julia indexing
end

# This would be used in the low-level API
# (not currently supported in high-level interface)
```
