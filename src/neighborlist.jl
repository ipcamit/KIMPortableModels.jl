"""
Minimal KIM-API neighbor list module using NeighbourLists.jl
"""

# Container for neighbor list data
mutable struct NeighborListContainer
    neighbors::Vector{Vector{Int32}}  # Pre-computed neighbors for each atom
    temp_storage::Vector{Int32}      # Reusable storage for current query
end

"""
create_kim_neighborlists(positions, cutoffs, species; cell=nothing, pbc=[true,true,true])

Create neighbor lists for KIM-API with ghost atoms for PBC.
    
Returns: (containers, all_positions, all_species, contributing, atom_indices)
- containers: Neighbor list data for each cutoff
- all_positions: Positions including ghost atoms  
- all_species: Species including ghost atoms
- contributing: 1 for real atoms, 0 for ghosts
- atom_indices: Original atom index for each position


TODO: Handle will_not_request_ghost_neigh logic, I just need to compute neighbors for ghost atoms as well.
"""
function create_kim_neighborlists(
    positions::Vector{SVector{3,Float64}}, 
    cutoffs::Vector{Float64},
    species::Vector{String};
    cell::Union{Matrix{Float64},Nothing}=nothing,
    pbc::Vector{Bool}=[true,true,true],
    will_not_request_ghost_neigh::Bool=false
    )
    any(pbc) && isnothing(cell) && error("Need cell for periodic boundaries")
    
    max_cutoff = maximum(cutoffs)
    pl = PairList(positions, max_cutoff, cell, pbc)
    
    all_positions = copy(positions)
    atom_indices = collect(Int32, 1:length(positions))
    n_real = length(positions)
    ghost_idx = n_real
    ghost_atom_ids = copy(pl.j)
    
    # Add ghost atoms
    for i in 1:n_real
        for j in pl.first[i]:pl.first[i+1]-1
            if !iszero(pl.S[j])
                ghost_pos = positions[pl.j[j]] + cell * pl.S[j]
                push!(all_positions, ghost_pos)
                push!(atom_indices, pl.j[j])
                ghost_idx += 1
                ghost_atom_ids[j] = ghost_idx
            end
        end
    end
    
    all_species = species[atom_indices]
    contributing = vcat(ones(Cint, n_real), zeros(Cint, length(all_positions) - n_real))
    
    # Create containers for each cutoff
    containers = NeighborListContainer[]
    
    for cutoff in cutoffs
        pl_cut = PairList(all_positions, cutoff, cell, [false, false, false])
        
        all_neighbors = Vector{Vector{Int32}}()
        for i in 1:n_real
            neighbors = pl_cut.j[pl_cut.first[i]:pl_cut.first[i+1]-1]
            push!(all_neighbors, neighbors)
        end
        
        # Add empty lists for ghost atoms
        for i in (n_real+1):length(all_positions)
            push!(all_neighbors, Int32[])
        end
        
        push!(containers, NeighborListContainer(all_neighbors, Int32[]))
    end
    
    return containers, all_positions, all_species, contributing, atom_indices
end

"""
kim_neighbors_callback(...)

KIM-API callback for neighbor queries. All indices are 0-based from KIM.
"""
function kim_neighbors_callback(
    data_ptr::Ptr{Cvoid},
    n_lists::Cint,
    cutoffs::Ptr{Cdouble},
    list_idx::Cint,
    particle_idx::Cint,
    n_neighbors_ptr::Ptr{Cint},
    neighbors_ptr::Ptr{Ptr{Cint}}
)::Cint
    println("kim_neighbors_callback: list_idx=$(list_idx), particle_idx=$(particle_idx)")
    try
        
        if data_ptr == C_NULL
            unsafe_store!(n_neighbors_ptr, Cint(0))
            return Cint(0)  # FOR DEBUGGING ONLY
        end
        
        containers = unsafe_pointer_to_objref(data_ptr)::Vector{NeighborListContainer}
        if list_idx < 0 || list_idx >= n_lists
            return Cint(1)
        end
        container_idx = list_idx + 1
        container = containers[container_idx]
        
        particle_1based = particle_idx + 1
        neighbors = container.neighbors[particle_1based]
        
        resize!(container.temp_storage, length(neighbors))
        container.temp_storage .= neighbors .- 1
        
        # Set outputs
        unsafe_store!(n_neighbors_ptr, Cint(length(neighbors)))
        unsafe_store!(neighbors_ptr, pointer(container.temp_storage))
        
        return Cint(0)
    catch e
        return Cint(1)
    end
end

macro cast_as_kim_neigh_fptr(func)
    quote
        @cfunction(
            $func,
            Cint,
            (Ptr{Cvoid}, Cint, Ptr{Cdouble}, Cint, Cint, Ptr{Cint}, Ptr{Ptr{Cint}})
        )
    end
end

export create_kim_neighborlists, kim_neighbors_callback, cast_as_kim_neigh_fptr