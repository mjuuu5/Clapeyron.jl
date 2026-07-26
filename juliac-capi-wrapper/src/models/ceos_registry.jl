module EOSRegistry

using ..CEOSBuild

const _eos_aliases = Dict(
    "PT" => "PatelTeja",
    "Patel-Teja" => "PatelTeja",
    "van der Waals" => "vdW",
    "VanDerWaals" => "vdW",
)

const _eos_models = Set([
    "vdW",
    "Clausius",
    "Berthelot",
    "RK",
    "SRK",
    "PSRK",
    "tcRK",
    "PR",
    "PR78",
    "VTPR",
    "TVTPR",
    "UMRPR",
    "QCPR",
    "cPR",
    "tcPR",
    "tcPRW",
    "EPPR78",
    "PatelTeja",
    "PTV",
    "YFR",
    "PatelTejaHeyen",
    "RKPR",
    "KU",
])

const _eos_builders = Dict{String,Function}(
    "PR" => CEOSBuild.build_pr,
)

function register_eos_builder(name::String, builder::Function; aliases::Vector{String}=String[])
    canonical = String(name)
    _eos_builders[canonical] = builder
    push!(_eos_models, canonical)
    for alias in aliases
        _eos_aliases[String(alias)] = canonical
    end
    return nothing
end

_resolve_model_name(model_name::String) = get(_eos_aliases, model_name, model_name)

function build_eos(model_name::String, components::Vector{String}, options::Dict{String,Any}, userlocations::Vector{String})
    canonical = _resolve_model_name(model_name)
    canonical in _eos_models || error("Unsupported EOS model: $(model_name)")

    if haskey(_eos_builders, canonical)
        return _eos_builders[canonical](components, options, userlocations)
    end
    return CEOSBuild.build_cubic(canonical, components, options, userlocations)
end

end # module CEOSRegistry