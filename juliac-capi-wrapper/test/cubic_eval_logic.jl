using Test
using JSON
using Clapeyron

include(joinpath(@__DIR__, "..", "src", "capi", "api_functions.jl"))
using .CAPI

function _alpha_for(model_name::String)
	return get(
		Dict(
			"vdW" => "NoAlpha",
			"Clausius" => "ClausiusAlpha",
			"Berthelot" => "ClausiusAlpha",
			"RK" => "RKAlpha",
			"SRK" => "SoaveAlpha",
			"PSRK" => "SoaveAlpha",
			"tcRK" => "RKAlpha",
			"PR" => "PRAlpha",
			"PR78" => "PR78Alpha",
			"VTPR" => "PRAlpha",
			"TVTPR" => "PRAlpha",
			"UMRPR" => "PRAlpha",
			"QCPR" => "PRAlpha",
			"cPR" => "TwuAlpha",
			"tcPR" => "tcTwuAlpha",
			"tcPRW" => "tcTwuAlpha",
			"EPPR78" => "PR78Alpha",
			"PatelTeja" => "PatelTejaAlpha",
			"PTV" => "PTVAlpha",
			"YFR" => "PTVAlpha",
			"PatelTejaHeyen" => "PatelTejaAlpha",
			"RKPR" => "RKPRAlpha",
			"KU" => "KUAlpha",
			"PT" => "PatelTejaAlpha",
			"Patel-Teja" => "PatelTejaAlpha",
		),
		model_name,
		"PRAlpha",
	)
end

function schema_ceos_spec(
	model_name::String;
	components = Any[
		Dict("name" => "ethane", "userlocations" => String[]),
		Dict("name" => "undecane", "userlocations" => String[]),
	],
	options::Dict{String, Any} = Dict{String, Any}(),
	metadata = Dict{String, Any}("spec_version" => "1.0", "trace_id" => nothing),
	extra = Dict{String, Any}(),
)
	merged_options = Dict{String, Any}(
		"idealmodel" => "BasicIdeal",
		"alpha" => _alpha_for(model_name),
		"mixing_rule" => "vdW1fRule",
		"translation" => "NoTranslation",
		"verbose" => false,
	)
	merge!(merged_options, options)
	spec = Dict{String, Any}(
		"kind" => "eos",
		"family" => "cubic",
		"model" => Dict{String, Any}("name" => "ceos", "variant" => model_name),
		"components" => components,
		"options" => merged_options,
		"metadata" => metadata,
	)
	merge!(spec, extra)
	return JSON.json(spec)
end

function schema_eos_spec(
	model_name::String;
	family::String = "cubic",
	components = Any[
		Dict("name" => "methane", "userlocations" => String[]),
		Dict("name" => "ethane", "userlocations" => String[]),
	],
	options::Dict{String, Any} = Dict{String, Any}(),
	parameters = Dict{String, Any}(),
	metadata = Dict{String, Any}("spec_version" => "1.0", "trace_id" => nothing),
	model_extra::Dict{String, Any} = Dict{String, Any}(),
	extra = Dict{String, Any}(),
)
	merged_options = Dict{String, Any}(
		"idealmodel" => "BasicIdeal",
		"alpha" => _alpha_for(model_name),
		"mixing_rule" => "vdW1fRule",
		"translation" => "NoTranslation",
		"verbose" => false,
	)
	merge!(merged_options, options)

	model_obj = Dict{String, Any}("name" => model_name)
	merge!(model_obj, model_extra)

	spec = Dict{String, Any}(
		"kind" => "eos",
		"family" => family,
		"model" => model_obj,
		"components" => components,
		"options" => merged_options,
		"metadata" => metadata,
	)
	isempty(parameters) || (spec["parameters"] = parameters)
	merge!(spec, extra)
	return JSON.json(spec)
end

@testset "CEOS generic cubic creation coverage" begin
	ceos_models = [
		("vdW", nothing),
		("Clausius", nothing),
		("Berthelot", nothing),
		("RK", nothing),
		("SRK", nothing),
		("PSRK", nothing),
		("tcRK", nothing),
		("PR", nothing),
		("PR78", nothing),
		("VTPR", nothing),
		("TVTPR", nothing),
		("UMRPR", nothing),
		("QCPR", Any[
			Dict("name" => "neon", "userlocations" => String[]),
			Dict("name" => "helium", "userlocations" => String[]),
		]),
		("cPR", nothing),
		("tcPR", nothing),
		("tcPRW", nothing),
		("EPPR78", Any[
			Dict("name" => "benzene", "userlocations" => String[]),
			Dict("name" => "isooctane", "userlocations" => String[]),
		]),
		("PatelTeja", nothing),
		("PTV", nothing),
		("YFR", nothing),
		("PatelTejaHeyen", nothing),
		("RKPR", nothing),
		("KU", nothing),
	]

	for (model_name, components) in ceos_models
		spec = isnothing(components) ? schema_ceos_spec(model_name) : schema_ceos_spec(model_name; components = components)
		handle = CAPI.create_model(spec)
		@test handle != 0
		@test CAPI.free_model(handle) == 0
	end
end

@testset "Cubic EOS variant and alias creation" begin
	alias_and_variant_cases = [
		("PT", Dict{String, Any}("variant" => "classic")),
		("Patel-Teja", Dict{String, Any}("variant" => "classic")),
		("PatelTeja", Dict{String, Any}("variant" => "classic")),
		("PTV", Dict{String, Any}("variant" => "valderrama")),
		("PR", Dict{String, Any}("variant" => "classic")),
	]
	for (model_name, model_extra) in alias_and_variant_cases
		handle = CAPI.create_model(schema_eos_spec(model_name; model_extra = model_extra))
		@test handle != 0
		@test CAPI.free_model(handle) == 0
	end

	function _create_ceos_model(model_name::String; components = nothing, options = Dict{String,Any}())
		spec = isnothing(components) ? schema_ceos_spec(model_name; options = options) : schema_ceos_spec(model_name; components = components, options = options)
		handle = CAPI.create_model(spec)
		return handle, CAPI._models[handle]
	end

	@testset "CEOS cubic value regression" begin
		T = 333.15
		V = 1e-3
		p = 1e5
		z = [0.5, 0.5]

		@testset "vdW/RK/PR core values" begin
			cases = [
				("vdW", -0.7088380780265725, -0.0002475728429728521),
				("RK", -0.9825375012134132, -0.00022230043592123767),
				("PR", -1.244774062489359, -0.0002328543992909459),
			]
			for (model_name, expected_ares, expected_poly) in cases
				handle, system = _create_ceos_model(model_name)
				try
					@test Clapeyron.a_res(system, V, T, z) ≈ expected_ares rtol = 1e-6
					@test Clapeyron.cubic_poly(system, p, T, z)[1][1] ≈ expected_poly rtol = 1e-6
					@test Clapeyron.cubic_p(system, V, T, z) ≈ Clapeyron.pressure(system, V, T, z) rtol = 1e-6
				finally
					@test CAPI.free_model(handle) == 0
				end
			end
		end

		@testset "Additional cubic variants" begin
			cases = [
				("SRK", -1.2640228781328529),
				("PR78", -1.246271020258271),
				("VTPR", -1.2363824487050494),
				("TVTPR", -1.2332185093557617),
				("UMRPR", -1.1447330557895619),
				("cPR", -1.2438144556398565),
				("tcPR", -1.254190142912733),
				("tcPRW", -1.2106271631685903),
				("PatelTeja", -1.2326465478280517),
				("PTV", -1.2696422558756286),
				("PatelTejaHeyen", -0.66377850749776),
				("RKPR", -1.2651155195427202),
				("KU", -1.2261554720898895),
			]
			for (model_name, expected_ares) in cases
				handle, system = _create_ceos_model(model_name)
				try
					@test Clapeyron.a_res(system, V, T, z) ≈ expected_ares rtol = 1e-6
				finally
					@test CAPI.free_model(handle) == 0
				end
			end
		end

		@testset "RK/PR option variants from cubic model tests" begin
			rk_component_mix = Any[
				Dict("name" => "methanol", "userlocations" => String[]),
				Dict("name" => "benzene", "userlocations" => String[]),
			]
			rk_cases = [
				("RK", Dict{String, Any}("alpha" => "BMAlpha"), nothing, -1.2569334957019538),
				("RK", Dict{String, Any}("translation" => "PenelouxTranslation"), nothing, -0.9819562816377636),
				("RK", Dict{String, Any}("translation" => "BaledTranslation"), nothing, -0.9851760769061726),
				("RK", Dict{String, Any}("mixing_rule" => "KayRule"), nothing, -0.8176850121211936),
				("RK", Dict{String, Any}("mixing_rule" => "HVRule", "activity_model" => "Wilson"), rk_component_mix, -0.5209112693371991),
				("RK", Dict{String, Any}("mixing_rule" => "MHV1Rule", "activity_model" => "Wilson"), rk_component_mix, -0.5091065987876959),
				("RK", Dict{String, Any}("mixing_rule" => "MHV2Rule", "activity_model" => "Wilson"), rk_component_mix, -0.5071048453490448),
				("RK", Dict{String, Any}("mixing_rule" => "WSRule", "activity_model" => "Wilson"), rk_component_mix, -0.5729126903890258),
				("RK", Dict{String, Any}("mixing_rule" => "modWSRule", "activity_model" => "Wilson"), rk_component_mix, -0.5531088611093051),
			]
			for (model_name, options, components, expected_ares) in rk_cases
				handle, system = isnothing(components) ? _create_ceos_model(model_name; options = options) : _create_ceos_model(model_name; options = options, components = components)
				try
					@test Clapeyron.a_res(system, V, T, z) ≈ expected_ares rtol = 1e-6
				finally
					@test CAPI.free_model(handle) == 0
				end
			end

			pr_component_mix = Any[
				Dict("name" => "methanol", "userlocations" => String[]),
				Dict("name" => "benzene", "userlocations" => String[]),
			]
			pr_cases = [
				("PR", Dict{String, Any}("alpha" => "BMAlpha"), nothing, -1.2445088818575114),
				("PR", Dict{String, Any}("alpha" => "TwuAlpha"), nothing, -1.2650756692036234),
				("PR", Dict{String, Any}("alpha" => "MTAlpha"), nothing, -1.2542346631395425),
				("PR", Dict{String, Any}("alpha" => "LeiboviciAlpha"), nothing, -1.2480909069722526),
				("PR", Dict{String, Any}("alpha" => "MC3PRAlpha"), nothing, -1.2557866200818528),
				("PR", Dict{String, Any}("translation" => "MTTranslation"), nothing, -1.243918482158021),
				("PR", Dict{String, Any}("translation" => "BaledTranslation"), nothing, -1.2438244560921463),
				("PR", Dict{String, Any}("mixing_rule" => "HVRule", "activity_model" => "Wilson"), pr_component_mix, -0.6329827794751909),
				("PR", Dict{String, Any}("mixing_rule" => "MHV1Rule", "activity_model" => "Wilson"), pr_component_mix, -0.6211441939544694),
				("PR", Dict{String, Any}("mixing_rule" => "MHV2Rule", "activity_model" => "Wilson"), pr_component_mix, -0.6210843663212396),
				("PR", Dict{String, Any}("mixing_rule" => "LCVMRule", "activity_model" => "Wilson"), pr_component_mix, -0.6286241404575419),
				("PR", Dict{String, Any}("mixing_rule" => "WSRule", "activity_model" => "Wilson"), pr_component_mix, -0.6690864227574802),
			]
			for (model_name, options, components, expected_ares) in pr_cases
				handle, system = isnothing(components) ? _create_ceos_model(model_name; options = options) : _create_ceos_model(model_name; options = options, components = components)
				try
					@test Clapeyron.a_res(system, V, T, z) ≈ expected_ares rtol = 1e-6
				finally
					@test CAPI.free_model(handle) == 0
				end
			end
		end

		@testset "Special composition/component cases" begin
			handle_qcpr, system_qcpr = _create_ceos_model(
				"QCPR";
				components = Any[
					Dict("name" => "neon", "userlocations" => String[]),
					Dict("name" => "helium", "userlocations" => String[]),
				],
			)
			try
				@test Clapeyron.a_res(system_qcpr, V, 25.0, z) ≈ -0.04727884027682022 rtol = 1e-6
				@test Clapeyron.lb_volume(system_qcpr, 25.0, z) ≈ 1.3601716423130568e-5 rtol = 1e-6
				a, b, c = Clapeyron.cubic_ab(system_qcpr, V, 25.0, z)
				@test a ≈ 0.012772722389495079 rtol = 1e-6
				@test b ≈ 1.0728356231510917e-5 rtol = 1e-6
				@test c ≈ -2.87335e-6 rtol = 1e-6

				handle_qcpr_single, system_qcpr_single = _create_ceos_model(
					"QCPR";
					components = Any[
						Dict("name" => "helium", "userlocations" => String[]),
					],
				)
				try
					a1 = Clapeyron.a_res(system_qcpr, V, 25.0, [0.0, 1.0])
					@test Clapeyron.a_res(system_qcpr_single, V, 25.0, [1.0]) ≈ a1 rtol = 1e-6
				finally
					@test CAPI.free_model(handle_qcpr_single) == 0
				end
			finally
				@test CAPI.free_model(handle_qcpr) == 0
			end

			handle_yfr, system_yfr = _create_ceos_model("YFR")
			try
				zz = [0.95, 0.05]
				@test Clapeyron.a_res(system_yfr, V, T, zz) ≈ 0.17277878581138775 rtol = 1e-6
				@test Clapeyron.cubic_p(system_yfr, V, T, zz) ≈ Clapeyron.pressure(system_yfr, V, T, zz) rtol = 1e-6
				@test Clapeyron.crit_pure(YFR("water"))[3] ≈ 6.50936094952025e-5 rtol = 1e-6
			finally
				@test CAPI.free_model(handle_yfr) == 0
			end

			handle_rkpr, system_rkpr = _create_ceos_model("RKPR")
			try
				d1, d2 = Clapeyron.cubic_Δ(system_rkpr, [0.0, 1.0])
				d10, d20 = Clapeyron.cubic_Δ(PR)
				@test d1 ≈ d10 rtol = 1e-6
				@test d2 ≈ d20 rtol = 1e-6
			finally
				@test CAPI.free_model(handle_rkpr) == 0
			end
		end
	end
end
