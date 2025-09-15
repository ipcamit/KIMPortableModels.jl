# KIM.jl

<p align="center">
<img src="./kimapijl.png" alt="KIM API JL Logo" width="300" />
</p>

Julia interface to the [KIM-API](https:https://kim-api.readthedocs.io) (Knowledgebase of Interatomic Models). 
This is a low-level interface to the KIM-API, allowing you to access interatomic models directly from Julia.
Think of it as the Julia equivalent of the KIMPY Python package.

[Documentation](https://ipcamit.github.io/KIM.jl/)

## Installation

For latest version:
```julia
using Pkg
Pkg.add(url="https://github.com/ipcamit/KIM.jl")
```

For stable version:
```julia
using Pkg
Pkg.add("KIM")
```

## Quick Start

Export the location of the KIM-API library:

```shell
export KIM_API_LIB=/path/to/libkim-api.so
```

Then, you can use the package as follows:

```julia
using KIM
using StaticArrays

# Create a model
model = KIM.KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")

# Setup atoms
positions = [SVector(0.0, 0.0, 0.0), SVector(2.7, 2.7, 0.0)]
species = ["Si", "Si"]
cell = [5.43 0.0 0.0; 0.0 5.43 0.0; 0.0 0.0 5.43]
pbc = [true, true, true]

# Calculate
results = model(species, positions, cell, pbc)
energy = results[:energy]
forces = results[:forces]
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

Full documentation is available at [https://ipcamit.github.io/KIM.jl/](https://ipcamit.github.io/KIM.jl/)

## Testing

Run the test suite with:

```julia
using Pkg
Pkg.test("KIM")
```

## TODO
- Move to 1 based numbering internally for consistency 
- Performance optimizations
- Additional model features support
- Test ML models

## License

MIT
