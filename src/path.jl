# JSONPath and everything related to defining it.

include("pattern.jl")

# Helper type for every Integer which isn't a Boolean (which in Julia is a
# subtype of Integer).
const VectorIndex = Union{Signed,Unsigned}

"""
Wildcards are used to match multiple keys or indices in a JSON path at once.
There are four types of wildcards:
- `ANY_KEY` - Matches any key in a `Dict`.
- `ANY_INDEX` - Matches any index in a `Vector`.
- `ANY` - Matches any key or in a `Dict` or index in a `Vector`.
- `SKIP_LIST` - If current value in the path is a `Vector`, matches all indices.
  If the current value is not a `Vector` it has no effect except for packing
  current value into a result Tuple with one element.

The wildcards can only be used for reading data, not for setting it.
"""
@enum JSONPathWildcard begin
    ANY
    ANY_KEY
    ANY_INDEX
    SKIP_LIST
end


"""
JSONPath is used to access and set the data in JSON serializable objects using
indexing. Below is the list of propertie of the JSONPath object:

## Properties that define the path
- `path` - A Tuple of keys and indices that defines the path to the value.

## Properties that spefify how to handle inserting data
- `parents` - If true, the path will be created if it doesn't exist.
- `candestroy` - If true, the path will be overwritten if it exists (including
  the parent values that are in the way).
- `canfilllists` - If true, the path will be created if it doesn't exist and the lists will be filled with the
  listfiller function.
- `listfiller` - This function is used to fill the lists when canfilllists is true.
"""
struct JSONPath
    path::Tuple{Vararg{Union{String,VectorIndex,JSONPathWildcard,StarPattern}}}
    parents::Bool
    candestroy::Bool
    canfilllists::Bool
    listfiller::Function

    """
    Create JSONPath using variadic arguments.
    """
    function JSONPath(
        args::Union{String,VectorIndex,JSONPathWildcard,StarPattern}...;
        parents::Bool=false,
        candestroy::Bool=false,
        canfilllists::Bool=false,
        listfiller::Function=() -> nothing)
        vect = Tuple{Vararg{Union{String,VectorIndex,JSONPathWildcard,StarPattern}}}(args)
        new(vect, parents, candestroy, canfilllists, listfiller)
    end
end

function Base.length(path::JSONPath)
    return length(path.path)
end

function Base.getindex(path::JSONPath, i::Int)
    return path.path[i]
end

function Base.firstindex(path::JSONPath)
    return firstindex(path.path)
end

function Base.lastindex(path::JSONPath)
    return lastindex(path.path)
end

"""
EndOfPath represents an error that occured during access to a JSON
path. EndOfPath is not an exception. It's just an enum with a few values which
may be useful for further processing.

# Fields
- `MISSING_KEY` - The requested key of an object is missing.
- `OUT_OF_BOUNDS` - The requested index of a list is out of bounds.
- `NOT_A_CONTAINER` - Requested access to an object which is not an object or a list.
- `INVALID_KEY_TYPE` - Requested access to an object using index or to a list using a key.
- `INVALID_ROOT` - The root object is not a Dict or a Vector. The errors that
  occure in the root object are separated because the `setindex!` function isn't
  able to modify the root object so the user might want to handle them in a different way.
"""
@enum EndOfPath begin
    MISSING_KEY
    OUT_OF_BOUNDS
    NOT_A_CONTAINER
    INVALID_KEY_TYPE
    INVALID_ROOT
end