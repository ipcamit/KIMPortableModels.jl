"""
KIM-API Julia Interface

A Julia wrapper for the KIM-API (Knowledgebase of Interatomic Models).
All functions must be accessed with the KIM_API prefix to avoid namespace pollution.

# Example
```julia
using kim_api
model = kim_api.KIMModel("ModelName")
results = model(species, positions, cell, pbc)
```
"""
module kim_api
using CEnum
using StaticArrays
using NeighbourLists
using Libdl

include("libkim.jl") # Load the KIM API library

include("constants.jl") # Default enumerations in kim-api

include("model.jl") # functions for model creation and destruction
                    # also includes ComputeArguments stuff for now

include("species.jl") # All the species related functions

include("neighborlist.jl") # Functions for creating neighbor lists

include("highlevel.jl") # Actual high-level API for model computation
end