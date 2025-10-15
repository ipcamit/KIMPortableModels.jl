"""
    neighborlist.jl

KIM-API neighbor list implementation using KIMNeighborList.jl.

This module provides efficient neighbor list generation and callback
functions for KIM-API models. It handles periodic boundary conditions
using a C++ implementation and provides the required callback interface
for KIM-API neighbor list queries.

# Key Types
- `NeighborListContainer`: Container for pre-computed neighbor lists

# Key Functions
- `create_kim_neighborlists`: Generate neighbor lists with C++ backend
- `kim_neighbors_callback`: KIM-API callback function for neighbor queries
- `@cast_as_kim_neigh_fptr`: Macro to create C function pointer for callbacks

# Implementation Details
The neighbor list implementation uses KIMNeighborList.jl (C++ backend) for efficient
spatial searching and automatically handles:
- Periodic boundary conditions via ghost atom generation
- Multiple cutoff distances (for models requiring multiple neighbor lists)
- Zero-based/one-based index conversions between Julia and KIM-API
- Memory management for callback data

# Performance Notes
Neighbor lists are computed on-demand using efficient C++ algorithms,
providing better performance than the previous NeighbourLists.jl implementation.
"""

"""
    NeighborListContainer

Container for neighbor list data with KIMNeighborList backend.

This mutable struct stores the neighbor list query function for efficient access during
KIM-API callback queries. It includes the query function and temporary storage
for index conversions.

# Fields
- `neighbors::Vector{Vector{Int32}}`: Pre-computed neighbors for each atom
- `temp_storage::Vector{Int32}`: Reusable storage for current neighbor query

# Notes
The `temp_storage` field is used to convert between Julia's 1-based
indexing and KIM-API's 0-based indexing during callback execution,
avoiding memory allocations in the hot path.
"""
mutable struct NeighborListContainer
    ptr::Ptr{Cvoid}
    is_valid::Bool
    temp_storage::Vector{Int32}      # Reusable storage for current query

    function NeighborListContainer(ptr::Ptr{Cvoid})
        handle = new(ptr, true, Vector{Int32}())

        finalizer(handle) do h
            if h.is_valid && h.ptr != C_NULL
                nbl_clean(h.ptr)
                h.is_valid = false
            end
        end
    end

end

"""
Create neighbor lists for KIM-API using KIMNeighborList C++ backend. It uses the lower level API of KIMNeighborList
to return all required information. Below is the copy pasted
code from the KIMNeighborList package

TODO: Add the desired function in KIMNeighborLists, so that
here it is blank call to the neighlist library?
    
Returns: (nl_container, all_coordinates, all_species, contributing, atom_indices)
- nl_container: Neighbor list data for each cutoff
- all_coordinates: Positions including ghost atoms  
- all_species: Species including ghost atoms
- contributing: 1 for real atoms, 0 for ghosts
- atom_indices: Original atom index for each position

The function creates neighbor lists for each cutoff using the KIMNeighborList backend
and handles ghost atom generation for periodic boundary conditions.
"""
function create_kim_neighborlists(
    species::Vector,
    coords::Vector{SVector{3,Float64}},
    cell::Matrix{Float64},
    pbc::Vector{Bool},
    cutoffs::Union{Real,Vector{Float64}};
    will_not_request_ghost_neigh::Bool = true,
)

    # Validate inputs
    length(species) == length(coords) ||
        throw(ArgumentError("species and coords must have same length"))
    size(cell) == (3, 3) || throw(ArgumentError("cell must be 3×3 matrix"))
    length(pbc) == 3 || throw(ArgumentError("pbc must be length 3"))
    padding_need_neigh = !will_not_request_ghost_neigh

    # Convert species to atomic symbols if they are numbers
    species_numbers = if eltype(species) <: AbstractString
        [KIMNeighborList.symbol_to_number(s) for s in species]
    else
        collect(Cint, species)
    end

    # Convert cutoffs to vector if single value
    cutoffs_vec = if isa(cutoffs, Number)
        [Float64(cutoffs)]
    else
        Vector{Float64}(cutoffs)
    end

    # Convert coordinates to matrix format for C++
    n_atoms = length(coords)
    # Julia uses column-major order, so hcat
    coords_matrix = reduce(hcat, coords) # col mat

    # Convert PBC to Int32
    pbc_int = Vector{Int32}(pbc)

    # Create padding atoms if PBC is enabled
    all_coords = coords_matrix
    all_species = species_numbers
    padding_offset = 0

    if any(pbc)
        influence_distance = maximum(cutoffs_vec)
        pad_coords_flat, pad_species, pad_image = nbl_create_paddings(
            influence_distance,
            cell,
            pbc_int,
            coords_matrix,
            Vector{Int32}(species_numbers),
        )

        if length(pad_species) > 0
            padding_offset = n_atoms
            # Convert flat padding coords to matrix
            npadding = length(pad_species)
            pad_coords_matrix = reshape(pad_coords_flat, 3, npadding)

            # Combine original and padding
            all_coords = hcat(coords_matrix, pad_coords_matrix) # col mat
            all_species = vcat(species_numbers, pad_species)
        end
    end

    # Create neighbor list
    nl_ptr = nbl_initialize()

    # Determine which atoms need neighbors
    # all_coords = Matrix(all_coords') # col mat
    total_atoms = size(all_coords, 2)
    need_neighbors = Vector{Int32}(undef, total_atoms)
    need_neighbors[1:n_atoms] .= 1  # Original atoms always need neighbors
    if padding_offset > 0
        # Padding atoms need neighbors only if requested
        need_neighbors[(n_atoms+1):end] .= padding_need_neigh ? 1 : 0
    end

    # Build neighbor list
    influence_distance = maximum(cutoffs_vec)
    error = nbl_build(nl_ptr, all_coords, influence_distance, cutoffs_vec, need_neighbors)
    if error != 0
        nbl_clean(nl_ptr)
        throw(ErrorException("Failed to build neighbor list (error code: $error)"))
    else
        # Wrap pointer in handle to manage memory
        nl_handle = NeighborListContainer(nl_ptr)
    end

    contributing = cat(ones(Cint, n_atoms), zeros(Cint, total_atoms - n_atoms); dims = 1)
    atom_indices = cat(collect(Cint, 1:n_atoms), pad_image .+ Cint(1); dims = 1) # 1 based indices

    # Return closure for neighbor queries
    return nl_handle, all_coords, all_species, contributing, atom_indices
end

"""
kim_neighbors_callback(...)

KIM-API callback for neighbor queries. All indices are 0-based from KIM.
"""
function kim_neighbors_callback(
    data_ptr::Ptr{Cvoid},
    n_lists::Cint,
    cutoffs::Ptr{Cdouble},
    list_idx::Cint, # 0 based
    particle_idx::Cint, # 0 based
    n_neighbors_ptr::Ptr{Cint},
    neighbors_ptr::Ptr{Ptr{Cint}},
)::Cint
    try
        if data_ptr == C_NULL
            unsafe_store!(n_neighbors_ptr, Cint(0))
            return Cint(0)
        end

        nl_handle = unsafe_pointer_to_objref(data_ptr)::NeighborListContainer

        if nl_handle.ptr == C_NULL
            error("Seems like NL ptr went out of scope")
            return Cint(0)
        end

        cutoffs_vec = unsafe_wrap(Array, cutoffs::Ptr{Cdouble}, n_lists)


        # Use the stored cutoffs vector from the container
        num_neighbors, neighbor_indices_0based =
            nbl_get_neigh(nl_handle.ptr, cutoffs_vec, list_idx, particle_idx)

        resize!(nl_handle.temp_storage, num_neighbors)
        copyto!(nl_handle.temp_storage, neighbor_indices_0based)

        unsafe_store!(n_neighbors_ptr, Cint(num_neighbors))
        unsafe_store!(neighbors_ptr, pointer(nl_handle.temp_storage))
        return Cint(0)
    catch e
        error(e)
        return Cint(1)
    end
end

"""
    @cast_as_kim_neigh_fptr(func)
Macro to create a C function pointer for KIM-API neighbor list callbacks.
This macro converts a Julia function into a C-compatible function pointer
for use with KIM-API's neighbor list interface.
"""
macro cast_as_kim_neigh_fptr(func)
    quote
        @cfunction(
            $func,
            Cint,
            (Ptr{Cvoid}, Cint, Ptr{Cdouble}, Cint, Cint, Ptr{Cint}, Ptr{Ptr{Cint}})
        )
    end
end

export create_kim_neighborlists, kim_neighbors_callback, @cast_as_kim_neigh_fptr
