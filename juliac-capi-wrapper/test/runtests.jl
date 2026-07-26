module TestRunner

using Test

function run_all_tests()
    println("Running all tests...")
    include("capi_eval_logic.jl")
    println("All tests completed.")
end

end # module

TestRunner.run_all_tests()