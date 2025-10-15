# KIMPortableModels.jl

<p align="center">
<img src="./kimapijl.png" alt="KIM API JL Logo" width="300" />
</p>

Julia interface to the [KIM-API](https:https://kim-api.readthedocs.io) (Knowledgebase of Interatomic Models). 
This is a low-level interface to the KIM-API, allowing you to access interatomic models directly from Julia.
Think of it as the Julia equivalent of the KIMPY Python package.

[Documentation](https://ipcamit.github.io/KIMPortableModels.jl/)

## Installation

For latest version:
```julia
using Pkg
Pkg.add(url="https://github.com/ipcamit/KIMPortableModels.jl")
```

For stable version:
```julia
using Pkg
Pkg.add("KIMPortableModels")
```

## Quick Start

Export the location of the KIM-API library:

```shell
export KIM_API_LIB=/path/to/libkim-api.so
```

Then, you can use the package as follows:

```julia
using KIMPortableModels, StaticArrays, LinearAlgebra

# Create model function
model = KIMPortableModels.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")

# Define system
species = ["Si", "Si"]
positions = [
    SVector(0.    , 0.    , 0.    ),
    SVector(1.3575, 1.3575, 1.3575),
]
cell = Matrix([[0.0 2.715 2.715] 
               [2.715 0.0 2.715] 
               [2.715 2.715 0.0]])
pbc = [true, true, true]

# Compute properties
results = model(species, positions, cell, pbc)
println("Energy: ", results[:energy])
println("Forces: ", results[:forces])
```

## Features

- Access to all KIM models
- Automatic neighbor list generation
- Support for periodic boundary conditions
- Multiple unit systems (metal, real, SI, CGS, electron)

## Requirements

- Julia 1.10+
- KIM-API library (for model calculations)
- KIMNeighborList.jl (C++ backend), StaticArrays.jl


## Documentation

Full documentation is available at [https://ipcamit.github.io/KIMPortableModels.jl/](https://ipcamit.github.io/KIMPortableModels.jl/)

## Testing

Run the test suite with:

```julia
using Pkg
Pkg.test("KIMPortableModels")
```

## TODO
- Move to 1 based numbering internally for consistency 
- Performance optimizations
- Additional model features support
- Test ML models

## License

MIT
