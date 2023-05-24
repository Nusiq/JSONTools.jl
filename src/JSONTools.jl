module JSONTools

export EndOfPath
export MISSING_KEY, OUT_OF_BOUNDS, NOT_A_CONTAINER, INVALID_KEY_TYPE, INVALID_ROOT
export safeaccessjson
export JSONToolsError
export JSONPath

"Helper type for every Integer which isn't a Boolean (which in Julia is a subtype of Integer)."
VectorIndex = Union{Signed,Unsigned}

"""
JSONToolsError is the base type for all errors from the JSONTools module.
"""
struct JSONToolsError <: Exception
    msg::String
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
    path::Vector{Union{String,VectorIndex}}
    parents::Bool
    candestroy::Bool
    canfilllists::Bool
    listfiller::Function

    """
    Create JSONPath using variadic arguments.
    """
    function JSONPath(
        args::Union{String,VectorIndex}...;
        parents::Bool=false,
        candestroy::Bool=false,
        canfilllists::Bool=false,
        listfiller::Function=() -> nothing)
        vect = Vector{Union{String,VectorIndex}}(undef, length(args))
        for (i, v) in enumerate(args)
            vect[i] = v
        end
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

"""
Access data in a JSON serializable object using valid JSON keys and indices. If
the path is invalid return an EndOfPath object instead of throwing an error.
"""
function safeaccessjson(data::Dict, key::String)
    if !haskey(data, key)
        return MISSING_KEY::EndOfPath
    end
    return data[key]
end

function safeaccessjson(data::Vector, key::VectorIndex)
    if length(data) < key
        return OUT_OF_BOUNDS::EndOfPath
    end
    return data[key]
end

# Invalid key (Dict, Vector)
function safeaccessjson(_::Dict, _::VectorIndex)
    return INVALID_KEY_TYPE::EndOfPath
end

function safeaccessjson(_::Vector, _::String)
    return INVALID_KEY_TYPE::EndOfPath
end

# Beyond the end of path
function safeaccessjson(data::EndOfPath, _::Union{String,VectorIndex})
    return data
end

# Invalid root
function safeaccessjson(_::Union{Nothing,Bool,Real,String}, _::Union{String,VectorIndex})
    return NOT_A_CONTAINER::EndOfPath
end

"""
Get the value from a Dict using given JSON path.
"""
function Base.getindex(data::Dict{K, V}, index::JSONPath) where {K, V}
    for k in index.path
        data = safeaccessjson(data, k)
        if data isa EndOfPath
            return data
        end
    end
    return data
end

"""
Get the value from a Vector using given JSON path.
"""
function Base.getindex(data::Vector{V}, index::JSONPath) where V
    for k in index.path
        data = safeaccessjson(data, k)
        if data isa EndOfPath
            return data
        end
    end
    return data
end

"""
Get the value from non-collection JSON serializable types. The function doesn't
throw an error only if the path is empty.
"""
function Base.getindex(data::Union{Nothing,Bool,Real,String,EndOfPath}, index::JSONPath)
    if length(index.path) == 0
        return data
    end
    return INVALID_ROOT
end

"""
Insert the value into the root object using given JSON path.
If the creation of the path is not possible raise an error.

Note that the function can't change the type of the root object. For example,
if the root is a Dict, the function can't change it to a Vector and the paths
that start with a numeric index will fail.

The details of the configuration are described in the JSONPath struct.
"""
function Base.setindex!(
        root::Dict{K, V},
        value::Union{Dict,Vector,Nothing,Bool,Real,String},
        path::JSONPath
) where {K, V}
    _setindex(root, value, path,)
end

function Base.setindex!(
        root::Vector{V},
        value::Union{Dict,Vector,Nothing,Bool,Real,String},
        path::JSONPath
) where V
    _setindex(root, value, path,)
end

"Redirection for the setindex! function to avoid the ambiguity error."
function _setindex(
    root::Union{Dict,Vector},
    value::Union{Dict,Vector,Nothing,Bool,Real,String},
    path::JSONPath
)
    # INITIAL CONDITIONS
    if length(path) == 0
        throw(JSONToolsError("The path must have at least one key."))
    end
    if isa(root, Dict) && isa(path[1], VectorIndex)
        throw(JSONToolsError("The root is an object but the path starts with a numeric index."))
    end
    if isa(root, Vector) && isa(path[1], String)
        throw(JSONToolsError("The root is a list but the path starts with a string key."))
    end
    curr = root
    # MIDDLE KEYS
    for i in 1:length(path)-1
        currk = path[i]
        nextk = path[i+1]

        # DETERMINE THE NEXT ITEM TYPE
        @assert nextk isa String || nextk isa VectorIndex  # Should always pass
        if nextk isa VectorIndex
            # VectorIndex keys require a Vector
            nextvaltype = Vector
        elseif nextk isa String
            # String keys require a Dict
            nextvaltype = Dict
        end

        # CREATE THE NEXT ITEM IF NECESSARY
        @assert curr isa Dict || curr isa Vector  # Should always pass
        if curr isa Dict
            @assert currk isa String  # Should always pass
            if !haskey(curr, currk)
                if !path.parents
                    throw(JSONToolsError("The path doesn't exist"))
                end
                curr[currk] = nextvaltype()
            elseif !isa(curr[currk], nextvaltype)  # In bounds wrong type
                if path.candestroy && path.parents
                    curr[currk] = nextvaltype()
                else
                    throw(JSONToolsError("Unable to overwrite existing path."))
                end
            end  # Path exists, nothing to do
        elseif curr isa Vector
            @assert currk isa VectorIndex  # Should always pass
            if length(curr) < currk  # This is out of bounds
                if path.canfilllists
                    while length(curr) < currk
                        push!(curr, path.listfiller())
                    end
                    curr[currk] = nextvaltype()
                else
                    throw(JSONToolsError("The index is out of bounds."))
                end
            elseif isa(curr[currk], nextvaltype)  # In bounds wrong type
                if path.candestroy && path.parents
                    curr[currk] = nextvaltype()
                else
                    throw(JSONToolsError("Unable to overwrite existing path."))
                end
            end # In bounds, nothing to do
        end

        # MOVE TO THE NEXT ITEM
        curr = curr[currk]
    end
    # LAST KEY
    @assert curr isa Dict || curr isa Vector  # Should always pass
    lastk = path[end]
    if curr isa Dict
        @assert lastk isa String  # Should always pass
        if (!haskey(curr, lastk) || path.candestroy)
            curr[lastk] = value
        else
            throw(JSONToolsError("Unable to overwrite existing path."))
        end
    elseif curr isa Vector
        @assert lastk isa VectorIndex  # Should always pass
        if length(curr) < lastk  # This is out of bounds
            if path.canfilllists
                while length(curr) < lastk
                    push!(curr, path.listfiller())
                end
                curr[lastk] = value
            else
                throw(JSONToolsError("The index is out of bounds."))
            end
        else  # This is in bounds
            if path.candestroy
                curr[lastk] = value
            else
                throw(JSONToolsError("Unable to overwrite existing path."))
            end
        end
    end
end

"""
Always return an error. This method is used to handle invalid root types.
"""
function Base.setindex!(
    _::Union{Nothing,Bool,Real,String},
    _::JSONPath,
    _::Union{Nothing,Bool,Real,String,Dict,Vector}
)
    throw(JSONToolsError("The root must be a Dict or a Vector."))
end


end  # module JSONTools