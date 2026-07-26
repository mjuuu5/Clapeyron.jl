# Toolchain for Windows Platform (64-bit)

This document outlines the necessary steps and requirements for setting up the build and compilation toolchain for the Juliac C API wrapper on the Windows platform, specifically targeting 64-bit architecture.

## Prerequisites

1. **Julia Installation**: Ensure that Julia (version 1.6 or later) is installed on your system. You can download it from the official [Julia website](https://julialang.org/downloads/).

2. **C Compiler**: A compatible C compiler is required. It is recommended to use:
   - **Microsoft Visual Studio**: Install the Desktop development with C++ workload.
   - **MinGW-w64**: An alternative option for a GCC-based compiler.

3. **CMake**: Install CMake (version 3.10 or later) to manage the build process. You can download it from the [CMake website](https://cmake.org/download/).

4. **Git**: Ensure that Git is installed for version control and managing dependencies.

## Setting Up the Environment

1. **Environment Variables**:
   - Add the path to your C compiler's `bin` directory to the `PATH` environment variable.
   - Set the `JULIA_BIN` environment variable to point to your Julia installation's `bin` directory.

2. **Install Required Julia Packages**:
   - Open Julia and run the following commands to install necessary packages:
     ```julia
     using Pkg
     Pkg.add("Cxx")
     Pkg.add("JSON")
     ```

## Building the Project

1. **Clone the Repository**:
   - Use Git to clone the project repository:
     ```bash
     git clone <repository-url>
     cd juliac-capi-wrapper
     ```

2. **Compile the C API**:
   - Navigate to the `interfaces/windows/x64` directory and create a build directory:
     ```bash
     mkdir build
     cd build
     ```

3. **Run CMake**:
   - Execute CMake to configure the project:
     ```bash
     cmake .. -G "Visual Studio 16 2019" -A x64
     ```
   - For MinGW-w64, use:
     ```bash
     cmake .. -G "MinGW Makefiles"
     ```

4. **Build the Project**:
   - For Visual Studio, open the generated solution file in Visual Studio and build the project.
   - For MinGW-w64, run:
     ```bash
     mingw32-make
     ```

## Testing the Build

1. **Run Tests**:
   - After building, navigate back to the root of the project and run the tests to ensure everything is functioning correctly:
     ```bash
     julia test/runtests.jl
     ```

## Troubleshooting

- If you encounter issues during the build process, ensure that all paths are correctly set and that the required tools are installed.
- Check the CMake output for any errors or warnings that may indicate missing dependencies or configuration issues.

## Conclusion

Following these steps will help you set up the necessary toolchain for building and running the Juliac C API wrapper on a Windows 64-bit platform. For further assistance, refer to the project's documentation or seek help from the community.