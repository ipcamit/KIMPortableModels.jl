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
include("libkim.jl")
include("constants.jl") 
include("model.jl")
include("species.jl")
include("neighborlist.jl")
include("highlevel.jl")
end