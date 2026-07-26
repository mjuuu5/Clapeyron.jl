module CAPIExports

using ClapeyronCAPI

# Exported functions for the C API
const Cint = Int32
const Cdouble = Float64
const Csize_t = UInt64

# Function to initialize the C API
Base.@ccallable function clapeyron_init()::Cint
    return ClapeyronCAPI.clapeyron_init()
end

# Function to shut down the C API
Base.@ccallable function clapeyron_shutdown()::Cint
    return ClapeyronCAPI.clapeyron_shutdown()
end

# Function to create a model
Base.@ccallable function clapeyron_create_model(spec::Ptr{Cchar})::UInt64
    handle = ClapeyronCAPI.clapeyron_create_model(spec)
    return handle
end

# Function to free a model
Base.@ccallable function clapeyron_free_model(handle::UInt64)::Cint
    return ClapeyronCAPI.clapeyron_free_model(handle)
end

end # module CAPIExports