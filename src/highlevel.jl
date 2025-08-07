# highlevel.jl
include("libkim.jl")
include("constants.jl")
include("model.jl")



"""
    KIMModel(model_name::String; units=UNIT_STYLES.metal, 
             neighbor_function=nothing, compute=[:energy, :forces]) -> Function
Create a KIM model function that computes properties for given species and positions.
The function returned will accept species codes and positions, and return requested computed properties.
"""
function KIMModel(model_name::String; 
                  units::Union{Symbol, Tuple{LengthUnit, EnergyUnit, ChargeUnit, TemperatureUnit, TimeUnit}} = :metal,
                  neighbor_function=nothing,
                  compute=[:energy, :forces],
                  species::Vector{} = nothing)
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
        units_in = (sorted_units...)
    model, accepted = create_model(Numbering(0), #TODO use one based numbering
                                   units_in...,
                                   model_name)
    !accepted && error("Units not accepted")
    
    args = create_compute_arguments(model)
    
    # Check what's supported
    supports = Dict(
        :energy => get_argument_support_status(args, partialEnergy),
        :forces => get_argument_support_status(args, partialForces),
        :virial => get_argument_support_status(args, partialVirial)
    )
    
    # Set neighbor callback if provided
    if neighbor_function !== nothing
        set_callback_pointer!(args, GetNeighborList, cpp, neighbor_function, C_NULL)
    end
    
    # Return closure
    return function(species, positions, cell=nothing)
        n = size(positions, 2)
        
        # Set pointers
        n_ref = Ref{Cint}(n)
        set_argument_pointer!(args, numberOfParticles, n_ref)
        set_argument_pointer!(args, particleSpeciesCodes,  )
        set_argument_pointer!(args, coordinates, positions)
        
        # Results storage
        results = Dict{Symbol,Any}()
        
        if :energy in compute && supports[:energy] != notSupported
            energy = Ref{Cdouble}(0.0)
            set_argument_pointer!(args, partialEnergy, energy)
            results[:energy] = energy
        end
        
        if :forces in compute && supports[:forces] != notSupported
            forces = zeros(3, n)
            set_argument_pointer!(args, partialForces, forces)
            results[:forces] = forces
        end
        
        # Compute
        compute!(model, args)
        
        # Return tuple of requested values
        return Tuple(get(results, k, nothing) for k in compute)
    end
end