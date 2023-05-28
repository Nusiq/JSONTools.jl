module JSONTools

export safeaccessjson
export JSONToolsError
export JSONPath

export EndOfPath
export MISSING_KEY, OUT_OF_BOUNDS, NOT_A_CONTAINER, INVALID_KEY_TYPE, INVALID_ROOT

export JSONPathWildcard
export ANY, ANY_KEY, ANY_INDEX, SKIP_LIST

include("exception.jl")
include("path.jl")


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
function safeaccessjson(data::EndOfPath, _::Union{String,VectorIndex,JSONPathWildcard})
    return data
end

# Invalid root
function safeaccessjson(_::Union{Nothing,Bool,Real,String}, _::Union{String,VectorIndex})
    return NOT_A_CONTAINER::EndOfPath
end

# Splitting paths with wildcards
function safeaccessjson(data::Dict, key::JSONPathWildcard)
    if key === ANY || key === ANY_KEY
        return tuple(values(data)...)
    elseif key === SKIP_LIST
        return tuple(data)
    end
    # ANY_INDEX
    return INVALID_KEY_TYPE::EndOfPath
end

function safeaccessjson(data::Vector, key::JSONPathWildcard)
    if key === ANY || key === ANY_INDEX || key === SKIP_LIST
        return tuple(data...)
    end
    # ANY_KEY
    return INVALID_KEY_TYPE::EndOfPath
end

# Wildcards on non-collections
function safeaccessjson(data::Union{Nothing,Bool,Real,String}, key::JSONPathWildcard)
    if key === SKIP_LIST
        return tuple(data)
    end
    # ANY_KEY or ANY or ANY_INDEX
    return INVALID_KEY_TYPE::EndOfPath
end

# Handling splitted paths (tuples automatically exclude EndOfPath objects)
function safeaccessjson(data::Tuple, key::Union{String,VectorIndex})
    apply = (data) -> (safeaccessjson(d, key) for d in data)
    filter = (data) -> (d for d in data if !isa(d, EndOfPath))
    return tuple((data |> apply |> filter)...)
end

function safeaccessjson(data::Tuple, key::JSONPathWildcard)
    # Apply function yields tuples becaus the key is a wildcard
    apply = (data) -> (safeaccessjson(d, key) for d in data)
    # Unpack yields values from the tuples, but skips EndOfPath objects
    unpack = (data) -> (
        item
        for subdata in data  # subdata is a tuple with actual values
        for item in subdata
        if !isa(item, EndOfPath)  # skip EndOfPath objects
    )
    return tuple((data |> apply |> unpack)...)
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
Get the value fron a Tuple. Every item of the tuple is treated as a root
object. The objects that return EndOfPath are excluded from the result tuple.
"""
function Base.getindex(data::Tuple, index::JSONPath)
    for k in index.path
        data = safeaccessjson(data, k)
        # The tuple can't return EndOfPath object because "safeaccessjson"
        # automatically excludes them from the result in case of a tuple
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

"Redirection for the setindex! function to avoid the ambiguity error."
function _setindex(
    root::Union{Dict,Vector},
    value::Union{Dict,Vector,Nothing,Bool,Real,String},
    path::JSONPath
)
    # INITIAL CONDITIONS
    if length(path) == 0
        throw(JSONToolsError("The path must have at least one key."))
    elseif isa(path[1], JSONPathWildcard)
        throw(JSONToolsError(
            "The paths with JSONPathWildcard can be used only for reading the data."))
    elseif isa(root, Dict) && isa(path[1], VectorIndex)
        throw(JSONToolsError("The root is an object but the path starts with a numeric index."))
    elseif isa(root, Vector) && isa(path[1], String)
        throw(JSONToolsError("The root is a list but the path starts with a string key."))
    end
    curr = root
    # MIDDLE KEYS
    for i in 1:length(path)-1
        currk = path[i]
        nextk = path[i+1]

        if isa(nextk, JSONPathWildcard)
            throw(JSONToolsError(
                "The paths with JSONPathWildcard can be used only for reading the data."))
        end

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

end  # module JSONTools