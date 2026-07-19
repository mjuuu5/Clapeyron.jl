module ClapeyronCAPI

using JSON
using Clapeyron

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



end # module
