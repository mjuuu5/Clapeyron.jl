module ClapeyronCAPI

using JSON
using Clapeyron

const _CLAPEYRON_VERSION = pkgversion(Clapeyron)

include("c_enums.jl")

const _models = Dict{UInt64,Any}()

function _next_handle()
    h = rand(UInt64)
    while haskey(_models,h)
        h = rand(UInt64)
    end
    return h
end

const Cint = Int32

Base.@ccallable function clapeyron_init()::Cint
    try
        # no-op: ensure Clapeyron is loaded
        return 0
    catch
        return -1
    end
end

Base.@ccallable function clapeyron_shutdown()::Cint
    try
        empty!(_models)
        return 0
    catch
        return -1
    end
end

  Base.@ccallable function clapeyron_create_model(spec::Ptr{Cchar})::UInt64
    try
        s = unsafe_string(spec)
        parsed = try
            JSON.parse(s)
        catch
            # fallback: store the raw string
            s
        end
        h = _next_handle()
        # For the initial implementation store the parsed spec (or raw string).
        # TODO: expand to construct concrete Clapeyron models from the spec.
        _models[h] = parsed
        return h
    catch
        return 0
    end
end

Base.@ccallable function clapeyron_free_model(handle::UInt64)::Cint
    if haskey(_models, handle)
        delete!(_models, handle)
        return 0
    else
        return -1
    end
end

Base.@ccallable function clapeyron_eval_eos(handle::UInt64, V::Cdouble, T::Cdouble, z_ptr::Ptr{Cdouble}, nz::Csize_t, out_ptr::Ptr{Cdouble})::Cint
    if !haskey(_models, handle)
        return -1
    end
    try
        z = unsafe_wrap(Vector{Float64}, z_ptr, Int(nz))
        model = _models[handle]
        # If a concrete model object is stored, call Clapeyron.eos
        if typeof(model) <: AbstractString
            return -2
        end
        val = Clapeyron.eos(model, V, T, z)
        unsafe_store!(out_ptr, val)
        return 0
    catch
        return -3
    end
end

Base.@ccallable function clapeyron_eval_eos_res(handle::UInt64, V::Cdouble, T::Cdouble, z_ptr::Ptr{Cdouble}, nz::Csize_t, out_ptr::Ptr{Cdouble})::Cint
    if !haskey(_models, handle)
        return -1
    end
    try
        z = unsafe_wrap(Vector{Float64}, z_ptr, Int(nz))
        model = _models[handle]
        if typeof(model) <: AbstractString
            return -2
        end
        val = Clapeyron.eos_res(model, V, T, z)
        unsafe_store!(out_ptr, val)
        return 0
    catch
        return -3
    end
end

end # module
