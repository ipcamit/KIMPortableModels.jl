# libkim.jl
using Libdl

# Try to find library automatically
_libkim = get(ENV, "KIM_API_LIB", find_library(["kim-api", "libkim-api"]))

if _libkim == ""
    error("""
    KIM-API library not found in system paths.
    Please set the environment variable KIM_API_LIB to the library path:
    
    ENV["KIM_API_LIB"] = "/path/to/libkim-api.so"
    
    Or install KIM-API and ensure it's in your system library path.
    """)
end

const libkim = _libkim
