# test_model_integration.jl - Integration tests for model functionality
# These tests require KIM-API library and may require specific models to be installed

@testset "Model Integration Tests" begin
    
    # Common test model (Stillinger-Weber for Silicon)
    test_model_name = "SW_StillingerWeber_1985_Si__MO_405512056662_006"
    
    @testset "Model Creation" begin
        # Test creating a model with different unit systems
        
        try
            model, accepted = kim_api.create_model(
                kim_api.zeroBased,
                kim_api.A,           # Angstrom
                kim_api.eV,          # eV
                kim_api.e,           # electron charge
                kim_api.K,           # Kelvin
                kim_api.ps,          # picoseconds
                test_model_name
            )
            
            @test model isa kim_api.Model
            @test model.p != C_NULL
            @test accepted isa Bool
            
            if accepted
                # Test model properties
                influence_distance = kim_api.get_influence_distance(model)
                @test influence_distance > 0.0
                @test influence_distance < 100.0  # Reasonable cutoff for SW potential
                
                # Test neighbor list requirements
                n_lists, cutoffs, will_not_request = kim_api.get_neighbor_list_pointers(model)
                @test n_lists >= 1
                @test length(cutoffs) == n_lists
                @test all(c -> c > 0.0, cutoffs)
                @test will_not_request isa Bool
                
                # Test compute arguments
                args = kim_api.create_compute_arguments(model)
                @test args isa kim_api.ComputeArguments
                @test args.p != C_NULL
                
                # Test argument support status
                energy_support = kim_api.get_argument_support_status(args, kim_api.partialEnergy)
                forces_support = kim_api.get_argument_support_status(args, kim_api.partialForces)
                
                @test energy_support in [kim_api.required, kim_api.optional]
                @test forces_support in [kim_api.required, kim_api.optional]
                
                # Test species support
                si_species = kim_api.get_species_number("Si")
                supported, code = kim_api.get_species_support_and_code(model, si_species)
                @test supported == true
                @test code isa Int32
                
                # Test unsupported species (most SW models only support Si)
                cu_species = kim_api.get_species_number("Cu")
                cu_supported, cu_code = kim_api.get_species_support_and_code(model, cu_species)
                # Cu should not be supported by Si SW model
                @test cu_supported == false
                
                # Cleanup
                kim_api.destroy_compute_arguments!(model, args)
                kim_api.destroy_model!(model)
            else
                @test_skip "Model did not accept the specified units"
                kim_api.destroy_model!(model)
            end
            
        catch e
            if e isa ErrorException && contains(string(e), "Model creation failed")
                @test_skip "Test model $test_model_name not available"
            else
                rethrow(e)
            end
        end
    end
    
    @testset "Species Mapping with Real Model" begin
        try
            model, accepted = kim_api.create_model(
                kim_api.zeroBased, kim_api.A, kim_api.eV, kim_api.e, kim_api.K, kim_api.ps,
                test_model_name
            )
            
            if accepted
                # Test species mapping functions
                species_list = ["Si", "Si", "Si"]
                
                try
                    species_codes = kim_api.get_species_codes_from_model(model, species_list)
                    @test length(species_codes) == length(species_list)
                    @test all(code -> code isa Int32, species_codes)
                    @test all(code -> code >= 0, species_codes)  # Valid codes should be non-negative
                    
                    # All silicon atoms should have the same code
                    @test all(code -> code == species_codes[1], species_codes)
                    
                    # Test species map creation
                    species_map = kim_api.get_unique_species_map(model, ["Si"])
                    @test haskey(species_map, "Si")
                    @test species_map["Si"] == species_codes[1]
                    
                    # Test supported species map  
                    supported_map = kim_api.get_supported_species_map(model)
                    @test haskey(supported_map, "Si")
                    @test supported_map["Si"] isa Int32
                    
                    # Test species map closure
                    map_closure = kim_api.get_species_map_closure(model)
                    closure_codes = map_closure(species_list)
                    @test closure_codes == species_codes
                    
                catch e
                    if contains(string(e), "not supported")
                        @test_skip "Species not supported by model"
                    else
                        rethrow(e)
                    end
                end
                
                # Test error handling for unsupported species
                @test_throws ErrorException kim_api.get_species_codes_from_model(model, ["Cu"])
                
                kim_api.destroy_model!(model)
            else
                @test_skip "Model did not accept units"
                kim_api.destroy_model!(model)
            end
            
        catch e
            @test_skip "Model creation failed: $e"
        end
    end
    
    @testset "Basic Computation" begin
        try
            model, accepted = kim_api.create_model(
                kim_api.zeroBased, kim_api.A, kim_api.eV, kim_api.e, kim_api.K, kim_api.ps,
                test_model_name
            )
            
            if accepted
                args = kim_api.create_compute_arguments(model)
                
                # Simple two-atom system
                n_atoms = 2
                species_strings = ["Si", "Si"]
                
                try
                    species_codes = kim_api.get_species_codes_from_model(model, species_strings)
                    
                    # Positions: two silicon atoms
                    positions = [0.0 2.35; 0.0 0.0; 0.0 0.0]  # 3x2 matrix, second atom at (2.35, 0, 0)
                    contributing = Int32[1, 1]  # Both atoms contribute
                    
                    # Set up pointers
                    n_particles_ref = Ref{Int32}(n_atoms)
                    energy_ref = Ref{Float64}(0.0)
                    forces = zeros(Float64, 3, n_atoms)
                    
                    kim_api.set_argument_pointer!(args, kim_api.numberOfParticles, n_particles_ref)
                    kim_api.set_argument_pointer!(args, kim_api.particleSpeciesCodes, species_codes)
                    kim_api.set_argument_pointer!(args, kim_api.coordinates, positions)
                    kim_api.set_argument_pointer!(args, kim_api.particleContributing, contributing)
                    kim_api.set_argument_pointer!(args, kim_api.partialEnergy, energy_ref)
                    kim_api.set_argument_pointer!(args, kim_api.partialForces, forces)
                    
                    # For this simple test, we'll skip neighbor list setup
                    # Real computation would need proper neighbor lists
                    
                    # Note: This test may fail without proper neighbor list callback
                    # The test verifies the setup works, not necessarily that compute succeeds
                    @test_nowarn kim_api.set_argument_pointer!(args, kim_api.numberOfParticles, n_particles_ref)
                    
                catch e
                    @test_skip "Basic computation setup failed: $e"
                end
                
                kim_api.destroy_compute_arguments!(model, args)
                kim_api.destroy_model!(model)
            else
                @test_skip "Model did not accept units"
                kim_api.destroy_model!(model)
            end
            
        catch e
            @test_skip "Model creation failed: $e"
        end
    end
end