# Juliac C API Wrapper

## Overview

The Juliac C API Wrapper is a Julia package designed to facilitate the interaction between Julia and C libraries, specifically focusing on the Clapeyron library for equation of state (EOS) modeling. This project provides a comprehensive interface for creating, managing, and evaluating EOS models through a C API, ensuring compatibility with Windows 64-bit architecture.

## Features

- **C API Integration**: Seamlessly wraps the Clapeyron C library, allowing users to leverage its functionality directly from Julia.
- **Model Management**: Provides utilities for creating, registering, and managing EOS models.
- **Error Handling**: Implements a robust error code system to communicate issues back to the C API.
- **JSON Specification Handling**: Includes tools for parsing and generating JSON specifications for model configurations.

## Installation

To install the Juliac C API Wrapper, clone the repository and use the Julia package manager:

```julia
using Pkg
Pkg.add("path/to/juliac-capi-wrapper")
```

## Usage

After installation, you can use the library as follows:

```julia
using JuliacCAPIWrapper

# Initialize the C API
clapeyron_init()

# Create a model
model_handle = clapeyron_create_model("model_spec.json")

# Evaluate the model
result = clapeyron_eval_eos(model_handle, volume, temperature, z_array, num_components, output_array)

# Free the model when done
clapeyron_free_model(model_handle)

# Shutdown the C API
clapeyron_shutdown()
```

## Documentation

For detailed documentation on the functions and their usage, refer to the following files:

- [Technical Requirements for Windows x64](docs/technical-requirements-windows-x64.md)
- [Function Execution Logic](docs/function-execution-logic.md)
- [C API Reference](docs/c-api-reference.md)

## Testing

The package includes a suite of tests to ensure functionality:

- `runtests.jl`: Entry point for running all tests.
- `capi_init_shutdown.jl`: Tests for initialization and shutdown of the C API.
- `capi_model_lifecycle.jl`: Tests for model creation, usage, and release.
- `capi_eval_logic.jl`: Tests for the evaluation logic of models.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.