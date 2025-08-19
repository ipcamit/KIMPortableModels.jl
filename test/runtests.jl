using Test
using kim_api
using StaticArrays
using LinearAlgebra

# Test suite for kim_api.jl

@testset "kim_api.jl Test Suite" begin
    
    # Only run integration tests if KIM-API library is available
    kim_available = try
        # Try to load the library to check if KIM-API is properly installed
        kim_api.libkim
        true
    catch e
        println("Warning: KIM-API library not available. Skipping integration tests.")
        println("Error: ", e)
        false
    end
    
    # Always run unit tests
    @testset "Unit Tests" begin
        include("test_constants.jl")
        include("test_species.jl") 
        include("test_neighborlist_unit.jl")
    end
    
    if kim_available
        @testset "Integration Tests" begin
            include("test_model_integration.jl")
            include("test_highlevel_integration.jl")
        end
    end
end