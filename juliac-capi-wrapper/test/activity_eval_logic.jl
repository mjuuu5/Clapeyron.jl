using Test
using JSON
using Clapeyron

include(joinpath(@__DIR__, "..", "src", "capi", "api_functions.jl"))
using .CAPI

function _created_model_from_spec(spec::String)
	handle = CAPI.create_model(spec)
	model = CAPI._models[handle]
	return handle, model
end

function schema_activity_spec(
	model_name::String;
	components = Any[
		Dict("name" => "water", "userlocations" => String[]),
		Dict("name" => "ethanol", "userlocations" => String[]),
	],
	options::Dict{String, Any} = Dict{String, Any}(),
	metadata = Dict{String, Any}("spec_version" => "1.0", "trace_id" => nothing),
	model_extra::Dict{String, Any} = Dict{String, Any}(),
	extra = Dict{String, Any}(),
)
	model_obj = Dict{String, Any}("name" => model_name)
	merge!(model_obj, model_extra)
	spec = Dict{String, Any}(
		"kind" => "activity",
		"family" => "activity",
		"model" => model_obj,
		"components" => components,
		"options" => options,
		"metadata" => metadata,
	)
	merge!(spec, extra)
	return JSON.json(spec)
end

@testset "Activity model creation coverage" begin
	acm_models = [
		("FloryHuggins", Dict{String, Any}()),
		("Margules", Dict{String, Any}()),
		("VanLaar", Dict{String, Any}()),
		("Wilson", Dict{String, Any}()),
		("tcPRWilsonRes", Dict{String, Any}()),
		("NRTL", Dict{String, Any}()),
		("aspenNRTL", Dict{String, Any}()),
		("UNIQUAC", Dict{String, Any}()),
	]

	for (model_name, options) in acm_models
		handle = CAPI.create_model(schema_activity_spec(model_name; options = options))
		@test handle != 0
		@test CAPI.free_model(handle) == 0
	end
end

@testset "ACM activity methods value checks" begin
	p = 1e5
	T = 298.15

	@testset "Activity methods, pure components" begin
		handle, system = _created_model_from_spec(
			schema_activity_spec("Wilson"; components = Any[Dict("name" => "methanol", "userlocations" => String[])]),
		)
		try
			@test Clapeyron.volume(system, p, T) ≈ 4.7367867309516085e-5 rtol = 1e-6
			@test Clapeyron.speed_of_sound(system, p, T) ≈ 2136.222735675237 rtol = 1e-6
			@test Clapeyron.crit_pure(system)[1] ≈ 512.6400000000001 rtol = 1e-6
			@test Clapeyron.saturation_pressure(system, T)[1] ≈ 15525.93630485447 rtol = 1e-6
		finally
			@test CAPI.free_model(handle) == 0
		end
	end

	@testset "Activity methods, multi-components" begin
		com = CompositeModel(["water", "methanol"], liquid = DIPPR105Liquid, saturation = DIPPR101Sat, gas = PR)
		com1 = split_model(com)[1]
		z = [0.5, 0.5]
		z_bulk = [0.2, 0.8]
		T2 = 320.15
		T3 = 300.15
		z3 = [0.9, 0.1]

		handle_wilson, system = _created_model_from_spec(
			schema_activity_spec("Wilson"; components = Any[
				Dict("name" => "methanol", "userlocations" => String[]),
				Dict("name" => "benzene", "userlocations" => String[]),
			]),
		)
		handle_nrtl, model3 = _created_model_from_spec(
			schema_activity_spec("NRTL"; components = Any[
				Dict("name" => "methanol", "userlocations" => String[]),
				Dict("name" => "hexane", "userlocations" => String[]),
			]),
		)
		try
			comp_system = CompositeModel(["methanol", "benzene"]; fluid = PR, liquid = Wilson, reference_state = :ashrae)
			system2 = if hasfield(Wilson, :puremodel)
				Wilson(["water", "methanol"], puremodel = com)
			else
				CompositeModel(["water", "methanol"], liquid = Wilson, fluid = com)
			end
			system3 = if hasfield(UNIFAC, :puremodel)
				UNIFAC(["octane", "heptane"], puremodel = LeeKeslerSat)
			else
				CompositeModel(["octane", "heptane"], liquid = UNIFAC, fluid = LeeKeslerSat)
			end

			@test crit_pure(com1)[1] ≈ 647.13
			@test Clapeyron.volume(system, p, T, z_bulk) ≈ 7.967897222918716e-5 rtol = 1e-6
			@test Clapeyron.volume(comp_system, p, T, z_bulk) ≈ 7.967897222918716e-5 rtol = 1e-6
			@test Clapeyron.mixing(system, p, T, z_bulk, Clapeyron.gibbs_free_energy) ≈ -356.86007792929263 rtol = 1e-6
			@test Clapeyron.mixing(system, p, T, z_bulk, Clapeyron.enthalpy) ≈ 519.0920708672975 rtol = 1e-6
			@test enthalpy(comp_system, p, T, z_bulk, phase = :v) - enthalpy(system, p, T, z_bulk, phase = :v) ≈ sum(reference_state(comp_system).a0 .* z_bulk) rtol = 1e-6

			@test Clapeyron.gibbs_solvation(system, T) ≈ -24707.145697543132 rtol = 1e-6
			pb1 = Clapeyron.bubble_pressure(system, T, z)[1]
			@test pb1 ≈ 23839.554959977086 rtol = 1e-6
			pb1b = Clapeyron.bubble_pressure(system, T, z, FugBubblePressure())[1]
			@test pb1b ≈ pb1 rtol = 1e-6
			@test Clapeyron.bubble_temperature(system, pb1, z)[1] ≈ T rtol = 1e-6

			pb2 = Clapeyron.bubble_pressure(system3, T3, z3)[1]
			@test pb2 ≈ 2460.897944633704 rtol = 1e-6
			pb2b = Clapeyron.bubble_pressure(system3, T3, z3, FugBubblePressure())[1]
			@test pb2b ≈ pb2 rtol = 1e-6
			@test Clapeyron.bubble_temperature(system3, pb2, z3)[1] ≈ T3 rtol = 1e-6

			pd1 = Clapeyron.dew_pressure(system2, T2, z)[1]
			@test pd1 ≈ 19393.924550078184 rtol = 1e-6
			pd1b = Clapeyron.dew_pressure(system2, T2, z, FugDewPressure(second_order = false))[1]
			@test pd1b ≈ pd1 rtol = 1e-6
			@test Clapeyron.dew_temperature(system2, pd1, z)[1] ≈ T2 rtol = 1e-6

			x1, _ = Clapeyron.LLE(model3, 290.0)
			@test x1[1] ≈ 0.15878439462531743 rtol = 1e-6
		finally
			@test CAPI.free_model(handle_wilson) == 0
			@test CAPI.free_model(handle_nrtl) == 0
		end
	end
end
