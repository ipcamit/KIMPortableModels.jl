# libkim.jl

"""
    libkim.jl

Library loading module for KIM-API.

This module handles the dynamic loading of the KIM-API shared library.
It attempts to find the library automatically in system paths, or uses
the environment variable KIM_API_LIB if provided.

# Environment Variables
- `KIM_API_LIB`: Path to the KIM-API shared library (e.g., "/path/to/libkim-api.so")

# Error Handling
Throws an error if the KIM-API library cannot be found in system paths
and the KIM_API_LIB environment variable is not set.
"""

# Try to find library automatically
_libkim = get(ENV, "KIM_API_LIB", find_library(["kim-api", "libkim-api"]))

if _libkim == ""
    println("""\033[1;31m
    ====================================================================
    WARNING:
    ====================================================================
    KIM-API library not found in system paths.
    Please set the environment variable KIM_API_LIB to the library path:

    ENV["KIM_API_LIB"] = "/path/to/libkim-api.so"

    Or install KIM-API and ensure it's in your system library path.
    OTHERWISE, KIM-API FUCNTIONALITY WILL NOT WORK AT RUNTIME.
    ====================================================================
    For more information, visit:
    www.openkim.org; kim-api.readthedocs.io
    ====================================================================
    \033[0m
    """)
end

const libkim = _libkim

function is_kim_available()
    return libkim != ""
end
