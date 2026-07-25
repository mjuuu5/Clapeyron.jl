# test_Clapeyron.jl — validates the C interface logic by loading LibClapeyron.jl as a
# regular Julia module and calling its @ccallable functions directly.
#
# This avoids loading the juliac-compiled libClapeyron.so from within a Julia
# process (which would trigger a second Julia runtime via jl_adopt_thread 
# and crash immediately).
#
# The compiled libClapeyron.so is validated separately by the C tests
# (test_all_solvers.c) which load it from a native C process 
# with no prior Julia runtime.
#
# Usage (from the Clapeyron.jl root):
#   julia --startup-file=no --project=. interfaces/test/test_Clapeyron.jl