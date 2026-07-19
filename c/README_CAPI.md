Clapeyron C API (experimental)

This folder contains a minimal C API header and example that call into a Julia module at `src/capi/ClapeyronCAPI.jl`.

Build (recommended paths)

1) Using PackageCompiler to create a shared library (Julia 1.9+)

```bash
# from repository root
julia --project -e 'using PackageCompiler; create_library("ClapeyronCAPI", ["src/capi/ClapeyronCAPI.jl"]; lib_name="libclapeyron")'
# produces libclapeyron(.so/.dylib/.dll) which exports the `Base.@ccallable` symbols
```

2) Using juliac (if installed)

```bash
# example (adjust to juliac CLI):
juliac build src/capi/ClapeyronCAPI.jl -o libclapeyron
```

Compile the example (adjust the shared library name and include path):

```bash
gcc -I. example.c -L. -lclapeyron -o example
./example
```

Notes
- The current Julia implementation stores model specs as opaque data; extending `clapeyron_create_model` to construct real `Clapeyron` model objects from JSON is the next step.
- Error codes: `0` == success. Negative values indicate various failures.
