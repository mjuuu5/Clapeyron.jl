module ACMRegistry

using ..ACMBuild

const _acm_models = Set([
    "FloryHuggins",
    "Margules",
    "VanLaar",
    "Wilson",
    "tcPRWilsonRes",
    "NRTL",
    "aspenNRTL",
    "UNIQUAC",
])

const _acm_builders = Dict{String,Function}(
    "FloryHuggins" => ACMBuild.build_flory_huggins,
)

function register_acm_builder(name::String, builder::Function)
    model_name = String(name)
    _acm_builders[model_name] = builder
    push!(_acm_models, model_name)
    return nothing
end

function build_activity(model_name::String, components::Vector{String}, options::Dict{String,Any}, userlocations::Vector{String})
    model_name in _acm_models || error("Unsupported activity model: $(model_name)")
    if haskey(_acm_builders, model_name)
        return _acm_builders[model_name](components, options, userlocations)
    end
    return ACMBuild.build_activity(model_name, components, options, userlocations)
end

end # module ACMRegistry