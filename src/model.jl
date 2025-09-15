# model.jl - KIM-API model initialization

"""
    model.jl

KIM-API model creation, management, and computation.

This module provides Julia wrappers for KIM-API model operations including:
- Model creation and destruction
- Compute arguments management
- Setting data pointers for calculations
- Executing model computations
- Neighbor list callback registration

# Core Types
- `Model`: Wrapper for KIM-API model pointer
- `ComputeArguments`: Wrapper for KIM-API compute arguments pointer

# Key Functions
- `create_model`: Initialize a KIM model with specified units
- `create_compute_arguments`: Create compute arguments container
- `set_argument_pointer!`: Set pointers to input/output data
- `compute!`: Execute the model calculation
- `get_influence_distance`: Get model's cutoff distance

# Memory Management
The Model and ComputeArguments types wrap C pointers and provide
destructor functions to prevent memory leaks.
"""

"""
    Model

Wrapper for KIM-API model pointer.

This mutable struct holds a pointer to a KIM-API model instance.
The pointer should be initialized using `create_model()` and
destroyed using `destroy_model!()` to prevent memory leaks.

# Fields
- `p::Ptr{Cvoid}`: C pointer to the KIM-API model
"""
mutable struct Model
    p::Ptr{Cvoid}
    Model() = new(C_NULL)
end

"""
    ComputeArguments

Wrapper for KIM-API compute arguments pointer.

This mutable struct holds a pointer to a KIM-API compute arguments
instance, which contains all the data needed for model calculations
including particle positions, species, and output arrays.

# Fields
- `p::Ptr{Cvoid}`: C pointer to the KIM-API compute arguments
"""
mutable struct ComputeArguments
    p::Ptr{Cvoid}
    ComputeArguments() = new(C_NULL)
end


"""
    create_model(numbering, length_unit, energy_unit, charge_unit, temperature_unit, time_unit, model_name) -> (Model, Bool)

Create a new KIM-API model instance with specified units.

# Arguments
- `numbering::Numbering`: Indexing scheme (zeroBased or oneBased)
- `length_unit::LengthUnit`: Length unit (A, Bohr, cm, m, nm)
- `energy_unit::EnergyUnit`: Energy unit (eV, J, kcal_mol, etc.)
- `charge_unit::ChargeUnit`: Charge unit (C, e, statC)
- `temperature_unit::TemperatureUnit`: Temperature unit (K)
- `time_unit::TimeUnit`: Time unit (fs, ps, ns, s)
- `model_name::String`: Name of the KIM model to load

# Returns
- `Model`: The created model instance
- `Bool`: Whether the specified units were accepted by the model

# Throws
- `ErrorException`: If model creation fails

# Example
```julia
model, accepted = create_model(
    zeroBased, A, eV, e, K, ps,
    "SW_StillingerWeber_1985_Si__MO_405512056662_006"
)
if !accepted
    error("Model rejected the specified units")
end
```
"""
function create_model(
    numbering::Numbering,
    length_unit::LengthUnit,
    energy_unit::EnergyUnit,
    charge_unit::ChargeUnit,
    temperature_unit::TemperatureUnit,
    time_unit::TimeUnit,
    model_name::String,
)
    model = Model()
    units_accepted = Ref{Cint}()

    model_ptr = Ref{Ptr{Cvoid}}(C_NULL)

    error_code = @ccall libkim.KIM_Model_Create(
        numbering::Cint,
        length_unit::Cint,
        energy_unit::Cint,
        charge_unit::Cint,
        temperature_unit::Cint,
        time_unit::Cint,
        model_name::Cstring,
        units_accepted::Ptr{Cint},
        model_ptr::Ptr{Ptr{Cvoid}},
    )::Cint

    if error_code != 0
        error("Model creation failed with error code: $error_code")
    end
    model.p = model_ptr[]

    return model, Bool(units_accepted[])
end

"""
    destroy_model!(model::Model)

Destroy a Model and free memory.
TODO: Is this needed? The model should automatically be destroyed when the Julia process exits.
"""
function destroy_model!(model::Model)
    if model.p != C_NULL
        @ccall libkim.KIM_Model_Destroy(Ref(model.p)::Ptr{Ptr{Cvoid}})::Cvoid
        model.p = C_NULL
    end
end



"""
    create_compute_arguments(model::Model) -> ComputeArguments

Create compute arguments for the model.
"""
function create_compute_arguments(model::Model)
    args = ComputeArguments()

    args_ptr = Ref{Ptr{Cvoid}}(C_NULL)
    error_code = @ccall libkim.KIM_Model_ComputeArgumentsCreate(
        model.p::Ptr{Cvoid},
        args_ptr::Ptr{Ptr{Cvoid}},
    )::Cint

    if error_code != 0
        error("ComputeArguments creation failed with error code: $error_code")
    end

    args.p = args_ptr[]

    return args
end

"""
    destroy_compute_arguments!(model::Model, args::ComputeArguments)

Destroy compute arguments.
"""
function destroy_compute_arguments!(model::Model, args::ComputeArguments)
    if args.p != C_NULL
        @ccall libkim.KIM_Model_ComputeArgumentsDestroy(
            model.p::Ptr{Cvoid},
            Ref(args.p)::Ptr{Ptr{Cvoid}},
        )::Cint
        args.p = C_NULL
    end
end



"""
    get_influence_distance(model::Model) -> Float64

Get the influence distance (cutoff) from the model.
"""
function get_influence_distance(model::Model)
    distance = Ref{Cdouble}()
    @ccall libkim.KIM_Model_GetInfluenceDistance(
        model.p::Ptr{Cvoid},
        distance::Ptr{Cdouble},
    )::Cvoid
    return distance[]
end

"""
    get_neighbor_list_pointers(model::Model) -> (n_lists, cutoffs, will_not_request)

Get neighbor list information from the model.
"""
function get_neighbor_list_pointers(model::Model)
    n_lists = Ref{Cint}()
    cutoffs_ptr = Ref{Ptr{Cdouble}}()
    will_not_request_ptr = Ref{Ptr{Cint}}()

    @ccall libkim.KIM_Model_GetNeighborListPointers(
        model.p::Ptr{Cvoid},
        n_lists::Ptr{Cint},
        cutoffs_ptr::Ptr{Ptr{Cdouble}},
        will_not_request_ptr::Ptr{Ptr{Cint}},
    )::Cvoid

    n = n_lists[]
    cutoffs = unsafe_wrap(Array, cutoffs_ptr[], n)
    will_not_request = unsafe_wrap(Array, will_not_request_ptr[], n)

    return n, cutoffs, Bool(will_not_request[1])
end


"""
    get_argument_support_status(args::ComputeArguments, arg_name::ComputeArgumentName) -> SupportStatus

Get the support status for a compute argument.
"""
function get_argument_support_status(args::ComputeArguments, arg_name::ComputeArgumentName)
    status = Ref{Cint}()

    @ccall libkim.KIM_ComputeArguments_GetArgumentSupportStatus(
        args.p::Ptr{Cvoid},
        arg_name::Cint,
        status::Ptr{Cint},
    )::Cvoid

    return SupportStatus(status[])
end



"""
    set_argument_pointer!(args::ComputeArguments, arg_name::ComputeArgumentName, ptr)

Set an integer argument pointer.
"""
function set_argument_pointer!(
    args::ComputeArguments,
    arg_name::ComputeArgumentName,
    ptr::Union{Ptr{Cint},Ref{Cint},Vector{Cint}},
)
    error_code = @ccall libkim.KIM_ComputeArguments_SetArgumentPointerInteger(
        args.p::Ptr{Cvoid},
        arg_name::Cint,
        ptr::Ptr{Cint},
    )::Cint

    if error_code != 0
        error("SetArgumentPointerInteger failed for $(arg_name)")
    end
end

"""
    set_argument_pointer!(args::ComputeArguments, arg_name::ComputeArgumentName, ptr)

Set a double argument pointer.
"""
function set_argument_pointer!(
    args::ComputeArguments,
    arg_name::ComputeArgumentName,
    ptr::Union{Ptr{Cdouble},Ref{Cdouble},Vector{Cdouble},Matrix{Cdouble}},
)
    error_code = @ccall libkim.KIM_ComputeArguments_SetArgumentPointerDouble(
        args.p::Ptr{Cvoid},
        arg_name::Cint,
        ptr::Ptr{Cdouble},
    )::Cint

    if error_code != 0
        error("SetArgumentPointerDouble failed for $(arg_name)")
    end
end



"""
    compute!(model::Model, args::ComputeArguments)

Execute the model computation.
"""
function compute!(model::Model, args::ComputeArguments)
    error_code =
        @ccall libkim.KIM_Model_Compute(model.p::Ptr{Cvoid}, args.p::Ptr{Cvoid})::Cint

    if error_code != 0
        error("Model compute failed with error code: $error_code")
    end
end

"""
    set_callback_pointer!(args::ComputeArguments, callback::ComputeCallbackName,
                         language::LanguageName, func_ptr, data_ptr)

Set a callback function pointer.
"""
function set_callback_pointer!(
    args::ComputeArguments,
    callback::ComputeCallbackName,
    language::LanguageName,
    func_ptr::Ptr{Cvoid},
    data_ptr::Ptr{Cvoid},
)
    error_code = @ccall libkim.KIM_ComputeArguments_SetCallbackPointer(
        args.p::Ptr{Cvoid},
        callback::Cint,
        language::Cint,
        func_ptr::Ptr{Cvoid},
        data_ptr::Ptr{Cvoid},
    )::Cint

    if error_code != 0
        error("SetCallbackPointer failed for $(callback)")
    end
end

# Export all types and functions
export Model, ComputeArguments, ModelRoutineName, DataType
export create_model, destroy_model!, set_log_id!
export create_compute_arguments, destroy_compute_arguments!
export get_influence_distance, get_neighbor_list_pointers
export get_argument_support_status
export set_argument_pointer!, set_callback_pointer!
export compute!
