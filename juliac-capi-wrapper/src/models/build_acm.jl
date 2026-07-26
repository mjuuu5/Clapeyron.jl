module ACMBuild

using Clapeyron

function _normalize_kwargs(options::Dict{String,Any}, userlocations::Vector{String})
    normalized = Dict{Symbol,Any}()
    for (key, value) in options
        normalized[Symbol(String(key))] = value
    end
    get!(normalized, :userlocations, userlocations)
    return normalized
end

function _default_flory_huggins_N(components::Vector{String})
    return fill(1.0, length(components))
end

function build_flory_huggins(components::Vector{String}, options::Dict{String,Any}, userlocations::Vector{String})
    kwargs = _normalize_kwargs(options, userlocations)
    N = pop!(kwargs, :N, _default_flory_huggins_N(components))
    return Clapeyron.FloryHuggins(components, N; (; pairs(kwargs)...)...)
end

function build_activity(model_name::String, components::Vector{String}, options::Dict{String,Any}, userlocations::Vector{String})
    kwargs = _normalize_kwargs(options, userlocations)
    model_sym = Symbol(model_name)
    isdefined(Clapeyron, model_sym) || error("Unsupported activity model: $(model_name)")
    constructor = getproperty(Clapeyron, model_sym)
    return constructor(components; (; pairs(kwargs)...)...)
end

end # module ACMBuild