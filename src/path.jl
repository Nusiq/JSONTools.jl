# JSONPath and everything related to defining it.

include("pattern.jl")

"Helper type for every Integer which isn't a Boolean (which in Julia is a subtype of Integer)."
VectorIndex = Union{Signed,Unsigned}

"""
JSONPathWildcard is a special type of an item in JSON path which makes
splitting paths possible. It has following values:
- ANY - Matches any key or index.
- ANY_KEY - Matches any key in an object.
- ANY_INDEX - Matches any index in a list.
- SKIP_LIST - If the next object is a list, skip it and match all of its 
  elements, otherwise do nothing. This is useful when the structure of the
  data in the JSON file can have one or many elements and when it has one it's
  allowed to be a single object instead of a list with one item.

The result of accessing JSON with a wildcard is always a tuple, even if the
wildcard matches only one item. This also applies to the SKIP_LIST wildcard.

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
indexing. The struct has following fields:
- path: A Vector of keys and indices that defines the path to the value.
- parents: Only used when setting values. If true, the path will be created
  if it doesn't exist.
- candestroy: Only used when setting values. If true, the path will be
  overwritten if it exists (including the parent values that are in the way).
- canfilllists: Only used when setting values. If true, the path will be
  created if it doesn't exist and the lists will be filled with the
  listfiller function.
- listfiller: Only used when setting values. This function is used to fill
  the lists when canfilllists is true.
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
path.

# Fields
- MISSING_KEY - The requested key of an object is missing.
- OUT_OF_BOUNDS - The requested index of a list is out of bounds.
- NOT_A_CONTAINER - Requested access to an object which is not an object or a list.
- INVALID_KEY_TYPE - Requested access to an object using index or to a list using a key.
- INVALID_ROOT - The root object is not a Dict or a Vector.
"""
@enum EndOfPath begin
    MISSING_KEY
    OUT_OF_BOUNDS
    NOT_A_CONTAINER
    INVALID_KEY_TYPE
    INVALID_ROOT
end