# Species Handling

Functions for managing chemical species in KIM-API.

## Types and Constants

```@docs
kim_api.SpeciesName
kim_api.SpeciesSymbols
```

## Basic Species Functions

```@docs
kim_api.get_species_number
kim_api.get_species_symbol
kim_api.species_name_known
kim_api.species_name_equal
kim_api.species_name_not_equal
```

## Model-Specific Species Functions

```@docs
kim_api.get_species_support_and_code
kim_api.get_species_codes_from_model
kim_api.get_unique_species_map
kim_api.get_supported_species_map
kim_api.get_species_map_closure
```

## Usage Examples

### Basic Species Lookup

```julia
# Convert species string to KIM number
si_number = get_species_number("Si")
ar_number = get_species_number("Ar")

# Convert back to string
@assert get_species_symbol(si_number) == "Si"

# Check if species is known
@assert species_name_known(si_number) == true
```

### Model-Specific Species Handling

```julia
using kim_api

# Create a model
model = KIMModel("SW_StillingerWeber_1985_Si__MO_405512056662_006")

# Get species codes for specific atoms
species_strings = ["Si", "Si", "Si"]
species_codes = get_species_codes_from_model(model, species_strings)

# Create efficient species mapping
species_map = get_unique_species_map(model, unique(species_strings))
println("Si has code: ", species_map["Si"])

# Create a reusable species mapper
mapper = get_species_map_closure(model)
codes = mapper(["Si", "Si"])  # Fast repeated mapping
```

### Error Handling

```julia
# This will throw an error if Cu is not supported by a Si-only model
try
    codes = get_species_codes_from_model(model, ["Cu"])
catch e
    println("Error: ", e)
    # Handle unsupported species
end
```