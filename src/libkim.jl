# libkim.jl

"""
    libkim.jl

Runtime handling for locating and loading the KIM-API shared library.

This module attempts to resolve `libkim-api` either from the environment
variable `KIM_API_LIB` or the system library paths. The resolution is
performed lazily so that the library can become available after the
package has been installed. A warning is emitted when the library cannot
be found; the heavy lifting functions rely on `is_kim_available()` to
fail fast before touching the C API.
"""

# Mutable reference so we can update the library once it becomes available.
libkim = ""

const _libkim_warning_shown = Ref(false)

"""
    _find_libkim_path() -> String

Best-effort search for the KIM-API shared library.
Returns an empty string when the library cannot be located.
"""
function _find_libkim_path()
    if haskey(ENV, "KIM_API_LIB")
        path = strip(ENV["KIM_API_LIB"])
        return isempty(path) ? "" : path
    end

    candidate = Libdl.find_library(["kim-api", "libkim-api"])
    candidate === nothing && return ""

    return String(Libdl.dlpath(candidate))
end

"""
    refresh_libkim!(; warn_if_missing=false) -> String

Re-evaluate the location of the KIM-API library and update `libkim`.
Optionally emits a warning if the library is still missing.
"""
function refresh_libkim!(; warn_if_missing::Bool = false)
    global libkim
    libkim = _find_libkim_path()

    if libkim == "" && warn_if_missing && !_libkim_warning_shown[]
        @warn "KIM-API shared library not found. Set `ENV[\"KIM_API_LIB\"] = \"/path/to/libkim-api.so\"` or install KIM-API so model evaluations can proceed."
        _libkim_warning_shown[] = true
    end

    return libkim
end

"""
    is_kim_available() -> Bool

Return `true` when the KIM-API library can be located.
The lookup is refreshed each time to pick up newly installed libraries.
"""
function is_kim_available()
    return refresh_libkim!() != ""
end

# Initialise once during module loading so the global is populated and a warning is emitted when appropriate.
refresh_libkim!(warn_if_missing = true)
