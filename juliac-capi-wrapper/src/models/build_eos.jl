module CEOSBuild

using Clapeyron

const _keyword_aliases = Dict(
    "mixing_rule" => "mixing",
    "activity_model" => "activity",
)

const _unsupported_options_by_model = Dict(
    "PSRK" => Set([:alpha, :mixing, :translation]),
    "VTPR" => Set([:mixing, :translation]),
    "TVTPR" => Set([:mixing, :translation]),
    "UMRPR" => Set([:alpha, :mixing, :translation]),
    "QCPR" => Set([:alpha, :mixing, :translation]),
    "cPR" => Set([:mixing, :translation]),
    "tcPR" => Set([:mixing, :translation]),
    "tcPRW" => Set([:mixing, :translation]),
    "EPPR78" => Set([:mixing, :translation]),
)

function _resolve_clapeyron_binding(name::String)
    sym = Symbol(name)
    isdefined(Clapeyron, sym) || error("Unsupported Clapeyron binding: $(name)")
    return getproperty(Clapeyron, sym)
end

function _normalize_keyword_value(key::String, value)
    if isnothing(value) || !(value isa AbstractString)
        return value
    elseif key in ("idealmodel", "alpha", "mixing", "activity", "translation")
        return _resolve_clapeyron_binding(String(value))
    else
        return value
    end
end

function _normalize_kwargs(options::Dict{String,Any}, userlocations::Vector{String})
    normalized = Dict{Symbol,Any}()
    for (key, value) in options
        normalized_key = get(_keyword_aliases, String(key), String(key))
        normalized[Symbol(normalized_key)] = _normalize_keyword_value(normalized_key, value)
    end
    get!(normalized, :userlocations, userlocations)
    return normalized
end

function _filter_model_kwargs(model_name::String, kwargs::Dict{Symbol,Any})
    blocked = get(_unsupported_options_by_model, model_name, Set{Symbol}())
    isempty(blocked) && return kwargs
    filtered = Dict{Symbol,Any}()
    for (key, value) in kwargs
        key in blocked && continue
        filtered[key] = value
    end
    return filtered
end

function build_cubic(model_name::String, components::Vector{String}, options::Dict{String,Any}, userlocations::Vector{String})
    kwargs = _filter_model_kwargs(model_name, _normalize_kwargs(options, userlocations))
    model_sym = Symbol(model_name)
    isdefined(Clapeyron, model_sym) || error("Unsupported EOS model: $(model_name)")
    constructor = getproperty(Clapeyron, model_sym)
    return constructor(components; (; pairs(kwargs)...)...)
end

function build_pr(components::Vector{String}, options::Dict{String,Any}, userlocations::Vector{String})
    return build_cubic("PR", components, options, userlocations)
end

end # module CEOSBuild