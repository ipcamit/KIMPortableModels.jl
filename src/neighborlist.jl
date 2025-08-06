using NeighbourLists
# TODO: Provide other nl backends too
using StaticArrays


"""
Object to contain the closure for neighbor list computation.
This is used to encapsulate the logic for neighbor list generation
in a way that can be passed to KIM.
This allows for a flexible interface where the user can pass their own 
neighbor list generation logic without needing to modify the KIM interface.
"""
mutable struct NeighborListContainer
    get_neighbors::Function  # The closure function
    neighbor_storage::Vector{Int32}  # Persistent storage for KIM
    
    function NeighborListContainer(get_neighbors_fn)
        new(get_neighbors_fn, Vector{Int32}())
    end
end

"""
Example wrapper function to register a neighbor list closure with KIM.
When supporting new simulators, this is the function that should be modified/
provided to KIM.
TODO: Provide more examples.
"""
function kim_neighbors_function(
    dataObject::Ptr{Cvoid},
    numberOfNeighborLists::Cint,
    cutoffs::Ptr{Cdouble},
    neighborListIndex::Cint,
    particleNumber::Cint,
    numberOfNeighbors::Ptr{Cint},
    neighborsOfParticle::Ptr{Ptr{Cint}}
)::Cint
    try
        nl_closure_list = unsafe_pointer_to_objref(dataObject)::Vector{NeighborListContainer}
        nl_closure = nl_closure_list[neighborListIndex + 1] # TODO: Let KIM-API handle this
        # return error if neighborListIndex is improper
        if neighborListIndex < 0 || neighborListIndex >= numberOfNeighborLists
            return Cint(1)
        end
        
        neighbors = nl_closure.get_neighbors(particleNumber + 1)
                
        # Convert to 0-based Int32 for KIM, TODO: Handle this in KIM-API
        nl_closure.neighbor_storage = Int32.(neighbors .- 1)
        
        # Set outputs
        unsafe_store!(numberOfNeighbors, length(neighbors))
        unsafe_store!(neighborsOfParticle, pointer(nl_closure.neighbor_storage))
        
        return Cint(0)
    catch e
        @error "Error in kim_neighbors_from_closure" exception=e
        return Cint(1)
    end
end


"""
    create_neighborlist_closure(positions::Vector{SVector{3, Float64}}, cutoff::Float64, cell::Matrix{Float64}, pbc::Vector{Bool}) -> Function
"""

function create_neighborlist_closure(positions::Vector{SVector{3, Float64}}, cutoff::Float64, cell::Matrix{Float64}=nothing, pbc::Vector{Bool}=[true, true, true])
    if isnothing(cell) && any(pbc)
        throw(ArgumentError("Cell must be provided if PBC is true"))
    end
    pl = PairList(positions, cutoff, cell, pbc)
    function get_neighbors(particle_idx::Int)
        nl, _ = neigs(pl, particle_idx)
        return nl
    end
    
    return get_neighbors
end

"""
List of NL containers to be passed to KIM.
"""
function create_kim_neighborlist_dataobject(positions::Vector{SVector{3, Float64}}, cutoffs::Vector{Float64}, cell::Matrix{Float64}=nothing, pbc::Vector{Bool}=[true, true, true])
    nl_container = Vector{NeighborListContainer}()
    for cutoff in cutoffs
        get_neighbors_fn = create_neighborlist_closure(positions, cutoff, cell, pbc)
        push!(nl_container, NeighborListContainer(get_neighbors_fn))
    end
    return nl_container
end