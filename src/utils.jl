"""
# Utility functions for various operations in the project.
"""

"""
    scatter_add!(dst::AbstractArray, src::AbstractArray, idx::AbstractArray; dims=1)
Perform a scatter-add operation in-place.
This function adds elements from `src` to `dst` at the indices specified by `idx`.
It is useful for accumulating results in a pre-allocated destination vector.
# Arguments
- `dst::AbstractArray`: Destination vector where elements will be added.
- `src::AbstractArray`: Source vector whose elements are added to `dst`.
- `idx::AbstractArray{<:Integer}`: Indices in `dst` where `src` elements will be added.
- `dims::Int`: Dimension along which to scatter-add. Default is 1.
# Returns
- The modified `dst` vector with accumulated results.
"""
function scatter_add!(dst::AbstractArray, src::AbstractArray, idx::AbstractArray; dims = 1)
    if ndims(src) == 1
        @inbounds @simd for i in eachindex(src, idx)
            dst[idx[i]] += src[i]
        end
    else
        @inbounds for I in CartesianIndices(src)
            inds = [I.I...]
            inds[dims] = idx[I.I[dims]]
            dst[inds...] += src[I]
        end
    end
    return dst
end

"""
    add_forces(idx::AbstractArray{<:Integer}, src::AbstractArray)
Perform a scatter-add operation to accumulate forces.
This function is specifically designed to accumulate forces from multiple atoms
into a single destination array based on the provided indices.
# Arguments
- `src::AbstractArray`: Source array containing forces to be added.
- `idx::AbstractArray{<:Integer}`: Indices in the destination array where
    forces will be accumulated.
# Returns
- A new array containing the accumulated forces at the specified indices.
# Note
- This function assumes that `idx` contains valid indices for the destination array.
- The destination array is initialized to zero before accumulation.
```
"""
@inline function add_forces(src::AbstractArray{T}, idx::AbstractArray{<:Integer}) where T
    max_idx = maximum(idx)
    dest = similar(src, T, (3, max_idx))
    fill!(dest, zero(T))
    scatter_add!(dest, src, idx, dims = 2)
    return dest
end

export scatter_add!, add_forces
