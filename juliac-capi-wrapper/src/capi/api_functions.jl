module CAPI

using JSON
using StructTypes

include(joinpath(@__DIR__, "..", "models", "build_eos.jl"))
include(joinpath(@__DIR__, "..", "models", "ceos_registry.jl"))
include(joinpath(@__DIR__, "..", "models", "build_acm.jl"))
include(joinpath(@__DIR__, "..", "models", "acm_registry.jl"))

using .EOSRegistry
using .ACMRegistry

Base.@kwdef struct ModelRef
    name::String
    variant::Union{Nothing,String} = nothing
end

Base.@kwdef struct ComponentRef
    name::String
    cas::Union{Nothing,String} = nothing
    use_user_data::Bool = false
    userlocations::Vector{String} = String[]
    metadata::Dict{String,Any} = Dict{String,Any}()
end

Base.@kwdef struct PureParameters
    Tc::Vector{Float64} = Float64[]
    Pc::Vector{Float64} = Float64[]
    Mw::Vector{Float64} = Float64[]
end

Base.@kwdef struct BinaryParameters
    kij::Vector{Vector{Float64}} = Vector{Vector{Float64}}()
    lij::Vector{Vector{Float64}} = Vector{Vector{Float64}}()
end

Base.@kwdef struct ParametersRef
    pure::PureParameters = PureParameters()
    binary::BinaryParameters = BinaryParameters()
end

Base.@kwdef struct MetadataRef
    spec_version::String
    trace_id::Union{Nothing,String} = nothing
    extra::Dict{String,Any} = Dict{String,Any}()
end

Base.@kwdef struct ModelSpec
    kind::String
    family::Union{Nothing,String} = nothing
    model::ModelRef
    components::Vector{ComponentRef}
    options::Dict{String,Any} = Dict{String,Any}()
    parameters::ParametersRef = ParametersRef()
    data::Dict{String,Any} = Dict{String,Any}()
    metadata::MetadataRef
end

StructTypes.StructType(::Type{ModelRef}) = StructTypes.Struct()
StructTypes.StructType(::Type{ComponentRef}) = StructTypes.Struct()
StructTypes.StructType(::Type{PureParameters}) = StructTypes.Struct()
StructTypes.StructType(::Type{BinaryParameters}) = StructTypes.Struct()
StructTypes.StructType(::Type{ParametersRef}) = StructTypes.Struct()
StructTypes.StructType(::Type{MetadataRef}) = StructTypes.Struct()
StructTypes.StructType(::Type{ModelSpec}) = StructTypes.Struct()

const _models = Dict{UInt64,Any}()
const _next_id = Ref{UInt64}(1)

_next_handle() = (_next_id[] += 1; _next_id[] - 1)

function _string_or_nothing(value)
    isnothing(value) && return nothing
    return String(value)
end

function _to_string_vector(values)
    out = String[]
    for value in values
        push!(out, String(value))
    end
    return out
end

function _to_float_vector(values)
    out = Float64[]
    for value in values
        push!(out, Float64(value))
    end
    return out
end

function _to_float_matrix(values)
    out = Vector{Vector{Float64}}()
    for row in values
        row isa AbstractVector || throw(ArgumentError("binary parameter matrix rows must be arrays"))
        push!(out, _to_float_vector(row))
    end
    return out
end

function _dict(value, field::String)
    value isa AbstractDict || throw(ArgumentError("$(field) must be an object"))
    return Dict{String,Any}(value)
end

function _parse_model_ref(raw)::ModelRef
    data = _dict(raw, "model")
    haskey(data, "name") || throw(ArgumentError("model.name is required"))
    return ModelRef(
        name = String(data["name"]),
        variant = _string_or_nothing(get(data, "variant", nothing)),
    )
end

function _parse_component(raw)::ComponentRef
    data = _dict(raw, "components[]")
    name = String(get(data, "name", ""))
    isempty(name) && throw(ArgumentError("components[].name is required"))
    return ComponentRef(
        name = name,
        cas = haskey(data, "cas") ? String(data["cas"]) : nothing,
        use_user_data = Bool(get(data, "use_user_data", false)),
        userlocations = _to_string_vector(get(data, "userlocations", Any[])),
        metadata = Dict{String,Any}(get(data, "metadata", Dict{String,Any}())),
    )
end

function _parse_parameters(raw)::ParametersRef
    data = _dict(raw, "parameters")
    pure_raw = haskey(data, "pure") ? _dict(data["pure"], "parameters.pure") : Dict{String,Any}()
    binary_raw = haskey(data, "binary") ? _dict(data["binary"], "parameters.binary") : Dict{String,Any}()
    return ParametersRef(
        pure = PureParameters(
            Tc = _to_float_vector(get(pure_raw, "Tc", Any[])),
            Pc = _to_float_vector(get(pure_raw, "Pc", Any[])),
            Mw = _to_float_vector(get(pure_raw, "Mw", Any[])),
        ),
        binary = BinaryParameters(
            kij = _to_float_matrix(get(binary_raw, "kij", Any[])),
            lij = _to_float_matrix(get(binary_raw, "lij", Any[])),
        ),
    )
end

function _parse_metadata(raw)::MetadataRef
    data = _dict(raw, "metadata")
    haskey(data, "spec_version") || throw(ArgumentError("metadata.spec_version is required"))
    extra = Dict{String,Any}(data)
    delete!(extra, "spec_version")
    haskey(extra, "trace_id") && delete!(extra, "trace_id")
    return MetadataRef(
        spec_version = String(data["spec_version"]),
        trace_id = _string_or_nothing(get(data, "trace_id", nothing)),
        extra = extra,
    )
end

function parse_model_spec(spec_json::String)::ModelSpec
    raw = JSON.parse(spec_json)
    root = _dict(raw, "spec")

    components_raw = get(root, "components", Any[])
    components_raw isa AbstractVector || throw(ArgumentError("components must be an array"))
    components = ComponentRef[]
    for component in components_raw
        push!(components, _parse_component(component))
    end

    options = haskey(root, "options") ? _dict(root["options"], "options") : Dict{String,Any}()
    parameters = haskey(root, "parameters") ? _parse_parameters(root["parameters"]) : ParametersRef()
    data = haskey(root, "data") ? _dict(root["data"], "data") : Dict{String,Any}()
    metadata = _parse_metadata(get(root, "metadata", Dict{String,Any}()))

    return ModelSpec(
        kind = String(get(root, "kind", "")),
        family = haskey(root, "family") ? String(root["family"]) : nothing,
        model = _parse_model_ref(get(root, "model", Dict{String,Any}())),
        components = components,
        options = options,
        parameters = parameters,
        data = data,
        metadata = metadata,
    )
end

function _validate_matrix_nxn(name::String, matrix::Vector{Vector{Float64}}, n::Int)
    isempty(matrix) && return
    length(matrix) == n || throw(ArgumentError("$(name) must have $(n) rows"))
    for (idx, row) in enumerate(matrix)
        length(row) == n || throw(ArgumentError("$(name) row $(idx) must have $(n) columns"))
    end
end

function validate_model_spec(spec::ModelSpec)
    spec.kind in ("eos", "activity") || throw(ArgumentError("kind must be \"eos\" or \"activity\""))
    isempty(spec.model.name) && throw(ArgumentError("model.name is required"))
    isempty(spec.components) && throw(ArgumentError("components must not be empty"))
    if spec.kind == "eos"
        haskey(spec.options, "idealmodel") || throw(ArgumentError("options.idealmodel is required"))
        haskey(spec.options, "alpha") || throw(ArgumentError("options.alpha is required"))
        if lowercase(spec.model.name) == "ceos"
            isnothing(spec.model.variant) && throw(ArgumentError("model.variant is required when model.name is \"ceos\""))
            isempty(spec.model.variant) && throw(ArgumentError("model.variant is required when model.name is \"ceos\""))
        end
    end

    ncomp = length(spec.components)
    pure = spec.parameters.pure
    binary = spec.parameters.binary

    isempty(pure.Tc) || length(pure.Tc) == ncomp || throw(ArgumentError("parameters.pure.Tc length must equal number of components"))
    isempty(pure.Pc) || length(pure.Pc) == ncomp || throw(ArgumentError("parameters.pure.Pc length must equal number of components"))
    _validate_matrix_nxn("parameters.binary.kij", binary.kij, ncomp)
    _validate_matrix_nxn("parameters.binary.lij", binary.lij, ncomp)

    return spec
end

function _all_userlocations(spec::ModelSpec)
    merged = String[]
    for component in spec.components
        append!(merged, component.userlocations)
    end
    if haskey(spec.data, "userlocations")
        append!(merged, _to_string_vector(spec.data["userlocations"]))
    end
    return unique(merged)
end

function create_model(spec_json::String)::UInt64
    spec = validate_model_spec(parse_model_spec(spec_json))
    component_names = [component.name for component in spec.components]
    userlocations = _all_userlocations(spec)
    model =
        if spec.kind == "eos"
            eos_name = lowercase(spec.model.name) == "ceos" ? spec.model.variant : spec.model.name
            EOSRegistry.build_eos(eos_name, component_names, spec.options, userlocations)
        else
            ACMRegistry.build_activity(spec.model.name, component_names, spec.options, userlocations)
        end

    handle = _next_handle()
    _models[handle] = model
    return handle
end

function free_model(handle::UInt64)::Int32
    haskey(_models, handle) || return Int32(-1)
    delete!(_models, handle)
    return Int32(0)
end

end # module CAPI
