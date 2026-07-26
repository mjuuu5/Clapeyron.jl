module JuliacCAPIWrapper

using JSON
using ClapeyronCAPI

const _VERSION = "0.1.0"

function main()
    clapeyron_init() == 0 || error("Failed to initialize Clapeyron C API")
    return
end

function shutdown()
    clapeyron_shutdown() == 0 || error("Failed to shutdown Clapeyron C API")
    return
end

function create_eos_model(model::String, components::Vector{String}; userlocations::Vector{String}=String[])
    spec = JSON.json(Dict(
        "kind" => "eos",
        "model" => model,
        "components" => components,
        "userlocations" => userlocations
    ))
    GC.@preserve spec begin
        return clapeyron_create_model(pointer(spec))
    end
end

function create_activity_model(model::String, components::Vector{String}; userlocations::Vector{String}=String[])
    spec = JSON.json(Dict(
        "kind" => "activity",
        "model" => model,
        "components" => components,
        "userlocations" => userlocations
    ))
    GC.@preserve spec begin
        return clapeyron_create_model(pointer(spec))
    end
end

end # module