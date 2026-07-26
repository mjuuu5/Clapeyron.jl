module ClapeyronCAPI

using Clapeyron

include(joinpath(@__DIR__, "capi", "api_functions.jl"))
using .CAPI

const Cint = Int32
const Cdouble = Float64
const Csize_t = UInt64

Base.@ccallable function clapeyron_init()::Cint
    return Cint(0)
end

Base.@ccallable function clapeyron_shutdown()::Cint
    empty!(CAPI._models)
    return Cint(0)
end

Base.@ccallable function clapeyron_create_model(spec::Ptr{Cchar})::UInt64
    spec == C_NULL && return UInt64(0)
    try
        return CAPI.create_model(unsafe_string(spec))
    catch
        return UInt64(0)
    end
end

Base.@ccallable function clapeyron_free_model(handle::UInt64)::Cint
    return CAPI.free_model(handle)
end

Base.@ccallable function clapeyron_eval_eos_res(
    handle::UInt64,
    V::Cdouble,
    T::Cdouble,
    z_ptr::Ptr{Cdouble},
    nz::Csize_t,
    out_val::Ptr{Cdouble},
)::Cint
    (z_ptr == C_NULL || out_val == C_NULL) && return Cint(-4)
    haskey(CAPI._models, handle) || return Cint(-1)
    try
        z = unsafe_wrap(Vector{Cdouble}, z_ptr, Int(nz))
        value = Clapeyron.a_res(CAPI._models[handle], V, T, z)
        unsafe_store!(out_val, value)
        return Cint(0)
    catch
        return Cint(-2)
    end
end

end # module ClapeyronCAPI
