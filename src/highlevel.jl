# highlevel.jl

"""
    KIMModel(model_name::String; units=UNIT_STYLES.metal, 
             neighbor_function=nothing, compute=[:energy, :forces]) -> Function
Create a KIM model function that computes properties for given species and positions.
The function returned will accept species codes and positions, and return requested computed properties.
"""
function KIMModel(model_name::String; 
                  units::Union{Symbol, Tuple{LengthUnit, EnergyUnit, ChargeUnit, TemperatureUnit, TimeUnit}} = :metal,
                  neighbor_function=nothing, #TODO: Handle neighbor function properly
                  compute=[:energy, :forces])
    # Initialize model
    if typeof(units) == Symbol
        units_in = get_lammps_style_units(units)
    elseif typeof(units) == Tuple
        # Ensure units are in correct order
        if length(units) != 5
            error("Units tuple must have exactly 5 elements: (length_unit, energy_unit, charge_unit, temperature_unit, time_unit)")
        end
        sorted_units = []
        for unit_order in [:length, :energy, :charge, :temperature, :time]
            sorted_units = push!(sorted_units, getfield(units, Symbol(unit_order)))
        end
        units_in = (sorted_units...,)
    end
    
    model, accepted = create_model(Numbering(0), #TODO use one based numbering
                                   units_in...,
                                   model_name)
    if !accepted
        error("Units not accepted")
    end
    
    args = create_compute_arguments(model)
    
    # Check support status
    supports_energy = notSupported
    supports_forces = notSupported
    
    if :energy in compute
        supports_energy = get_argument_support_status(args, partialEnergy)
        if supports_energy == notSupported
            error("Model does not support energy computation")
        end
    end

    if :forces in compute
        supports_forces = get_argument_support_status(args, partialForces)
        if supports_forces == notSupported
            error("Model does not support forces computation")
        end
    end

    if length(compute) == 0
        error("At least one compute argument must be requested: :energy or :forces")
    end
    if length(compute) > 2
        error("Only :energy and :forces can be requested together")
    end

    # TODO: Add support for other compute arguments if needed

    # Set neighbor callback if provided
    n_cutoffs = 0
    cutoffs = Float64[]
    will_not_request_ghost_neigh = Int32[]
    
    if neighbor_function === nothing
        # default neighbor function
        n_cutoffs, cutoffs, will_not_request_ghost_neigh = get_neighbor_list_pointers(model)
        println("Model needs $n_cutoffs neighbor lists with cutoffs: $cutoffs")
    else
        error("TODO: Handle custom neighbor function")
    end

    
    species_support_map = get_species_map_closure(model)

    # Return closure
    return function _compute_model(species, positions, cell, pbc)
        # Create neighbor lists if needed
        if neighbor_function === nothing
            containers, all_positions, all_species, contributing, atom_indices = 
                create_kim_neighborlists(positions, cutoffs, species;
                cell=cell, pbc=pbc, 
                will_not_request_ghost_neigh=will_not_request_ghost_neigh)
            println("Created neighbor lists with $(all_positions) total positions including ghosts. $(containers)")
        else
            error("TODO: Neighbor function is not provided.")
        end
        
        particle_species_codes = species_support_map(all_species)
        # Set pointers
        
        coords = reduce(hcat, all_positions) # Vector{SVector} to Matrix{Cdouble/Float64}
        n = size(coords, 2)

        n_ref = Ref{Cint}(n)
        set_argument_pointer!(args, numberOfParticles, n_ref)
        set_argument_pointer!(args, particleSpeciesCodes, particle_species_codes)
        set_argument_pointer!(args, coordinates, coords)
        set_argument_pointer!(args, particleContributing, contributing)
        energy = Ref{Cdouble}(0.0)
        forces = zeros(3, n)
        
        # Results storage
        results = Dict{Symbol,Any}()
        
        if :energy in compute && supports_energy != notSupported
            set_argument_pointer!(args, partialEnergy, energy)
        end
        
        if :forces in compute && supports_forces != notSupported
            set_argument_pointer!(args, partialForces, forces)
        end

        # Set neighbor list if provided
        if neighbor_function === nothing
            GC.@preserve containers coords forces energy all_positions particle_species_codes begin
                fptr = kim_api.@cast_as_kim_neigh_fptr(kim_api.kim_neighbors_callback)
                data_obj_ptr = pointer_from_objref(containers)
                data_obj_ptr = pointer_from_objref(containers)                            
                set_callback_pointer!(args, GetNeighborList, c, fptr, data_obj_ptr)
                compute!(model, args)
            end
        else
            error("TODO: Handle custom neighbor function")
        end        
        println("Energy: $(energy[])")

        if :energy in compute && supports_energy != notSupported
            results[:energy] = energy[]
        end
        
        if :forces in compute && supports_forces != notSupported
            results[:forces] = forces
        end

        return results
    end
end


