module JSONTools
export EndOfPath
export MISSING_KEY, OUT_OF_BOUNDS, NOT_A_CONTAINER, INVALID_KEY_TYPE, INVALID_ROOT
export trackedaccessjson, quickaccessjson
export JSONPath
export JSONToolsError
export setvalue!

"Helper type for every Integer which isn't a Boolean (which in Julia is a subtype of Integer)."
VectorIndex = Union{Signed,Unsigned}

"""
JSONToolsError is the base type for all errors from the JSONTools module.
"""
struct JSONToolsError <: Exception
    msg::String
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

# QUICK
# Valid access (Dict, Vector)
"""
Access JSON path using valid keys on a valid JSON serializable object.
Return a value at the end of the path or an EndOfPath.
"""
function quickaccessjson(data::Dict, key::String)
    if !haskey(data, key)
        return MISSING_KEY::EndOfPath
    end
    return data[key]
end

function quickaccessjson(data::Vector, key::VectorIndex)
    if length(data) < key
        return OUT_OF_BOUNDS::EndOfPath
    end
    return data[key]
end

# Invalid key (Dict, Vector)
function quickaccessjson(_::Dict, _::VectorIndex)
    return INVALID_KEY_TYPE::EndOfPath
end

function quickaccessjson(_::Vector, _::String)
    return INVALID_KEY_TYPE::EndOfPath
end

# Beyond the end of path
function quickaccessjson(data::EndOfPath, _::Union{String,VectorIndex})
    return data
end

# Invalid root
function quickaccessjson(_::Union{Nothing,Bool,Real,String}, _::Union{String,VectorIndex})
    return NOT_A_CONTAINER::EndOfPath
end

# TRACKED
"""
Represents a path insida a JSON object.
"""
mutable struct JSONPath
    "The root of the path."
    root::Union{Dict,Vector,Nothing,Bool,Real,String}

    "The path as a vector of keys and indices."
    path::Vector{Union{String,VectorIndex}}

    "The value at the end of the path or an EndOfPath."
    value::Union{EndOfPath,Nothing,Bool,Real,String,Dict,Vector}
end
# Valid root access (Dict, Vector)
"""
Access JSON path using valid keys on a valid JSON serializable object.
Return a JSONPath object with the value at the end of the path or with an
EndOfPath.
"""
function trackedaccessjson(data::Dict, key::String)::JSONPath
    if !haskey(data, key)
        return JSONPath(data, [key,], MISSING_KEY::EndOfPath)
    end
    return JSONPath(data, [key,], data[key])
end

function trackedaccessjson(data::Vector, key::VectorIndex)::JSONPath
    if length(data) < key
        return JSONPath(data, [key,], OUT_OF_BOUNDS::EndOfPath)
    end
    return JSONPath(data, [key,], data[key])
end

# Invalid root access because of an invalid key (Dict, Vector)
function trackedaccessjson(data::Dict, key::VectorIndex)::JSONPath
    return JSONPath(data, [key,], INVALID_KEY_TYPE::EndOfPath)
end

function trackedaccessjson(data::Vector, key::String)::JSONPath
    return JSONPath(data, [key,], INVALID_KEY_TYPE::EndOfPath)
end

# Invalid root because of invalid root type (not a Dict and not a Vector)
function trackedaccessjson(
    data::Union{Nothing,Bool,Real,String},
    key::Union{String,VectorIndex}
)::JSONPath
    return JSONPath(data, [key,], INVALID_ROOT::EndOfPath)
end

# Continue JSON path
function trackedaccessjson(data::JSONPath, key::Union{String,VectorIndex})::JSONPath
    # Error propagation
    if isa(data.value, EndOfPath)
        return JSONPath(data.root, [data.path..., key], data.value)
    end
    # End of path primitives
    if !isa(data.value, Dict) && !isa(data.value, Vector)
        return JSONPath(data.root, [data.path..., key], NOT_A_CONTAINER::EndOfPath)
    end

    # Continue path
    next = trackedaccessjson(data.value, key)
    next.root = data.root
    next.path = [data.path..., key]
    return next
end

"""
Insert the value into the root object using given JSON path.
If the creation of the path is not possible raise an error.

Note that the function can't change the type of the root object. For example,
if the root is a Dict, the function can't change it to a Vector and the paths
that start with a numeric index will fail.

# Arguments
- root - the root object.
- path - The path to insert the value into.
- value - The value to insert.
- parents - If true, create missing parents.
- candestroy - If true, the function is allowed to destroy existing values that
  are in the way.
- canfilllists - If true, the function is allowed to fill lists with values
  is path points to a list index that is out of bounds.
- listfiller - A function that is called when the path points to a list and the
  index is out of bounds. The function is used to fill the list with values
  until the index is in bounds.
"""
function setvalue!(
    root::Union{Dict,Vector},
    path::Vector{Union{String,VectorIndex}},
    value::Union{Nothing,Bool,Real,String,Dict,Vector};
    parents::Bool=false,
    candestroy::Bool=false,
    canfilllists::Bool=false,
    listfiller::Function=() -> nothing
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
                if !parents
                    throw(JSONToolsError("The path doesn't exist"))
                end
                curr[currk] = nextvaltype()
            elseif !isa(curr[currk], nextvaltype)  # In bounds wrong type
                if candestroy && parents
                    curr[currk] = nextvaltype()
                else
                    throw(JSONToolsError("Unable to overwrite existing path."))
                end
            end  # Path exists, nothing to do
        elseif curr isa Vector
            @assert currk isa VectorIndex  # Should always pass
            if length(curr) < currk  # This is out of bounds
                if canfilllists
                    while length(curr) < currk
                        push!(curr, listfiller())
                    end
                    curr[currk] = nextvaltype()
                else
                    throw(JSONToolsError("The index is out of bounds."))
                end
            elseif isa(curr[currk], nextvaltype)  # In bounds wrong type
                if candestroy && parents
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
        if (!haskey(curr, lastk) || candestroy)
            curr[lastk] = value
        else
            throw(JSONToolsError("Unable to overwrite existing path."))
        end
    elseif curr isa Vector
        @assert lastk isa VectorIndex  # Should always pass
        if length(curr) < lastk  # This is out of bounds
            if canfilllists
                while length(curr) < lastk
                    push!(curr, listfiller())
                end
                curr[lastk] = value
            else
                throw(JSONToolsError("The index is out of bounds."))
            end
        else  # This is in bounds
            if candestroy
                curr[lastk] = value
            else
                throw(JSONToolsError("Unable to overwrite existing path."))
            end
        end
    end
end

"""
Insert the value using the JSONPath object. The path defines the root and
the path to the value.
"""
function setvalue!(
    path::JSONPath,
    value::Union{Nothing,Bool,Real,String,Dict,Vector};
    parents::Bool=false,
    candestroy::Bool=false,
    canfilllists::Bool=false,
    listfiller::Function=() -> nothing
)
    setvalue!(
        path.root,
        path.path,
        value;
        parents=parents,
        candestroy=candestroy,
        canfilllists=canfilllists,
        listfiller=listfiller
    )
end

"""
Always return an error. This method is used to handle invalid root types.
"""
function setvalue!(
    # Main args must be named due to a Julia bug
    # (https://github.com/JuliaLang/julia/issues/32727)
    root::Union{Nothing,Bool,Real,String},
    path::Vector,
    value::Union{Nothing,Bool,Real,String,Dict,Vector};
    # Kwargs for matching function signature
    parents::Bool=false,
    candestroy::Bool=false,
    canfilllists::Bool=false,
    listfiller::Function=() -> nothing
)
    throw(JSONToolsError("The root must be a Dict or a Vector."))
end

# Assets that the vector values are using the correct type
function setvalue!(
    root::Union{Dict,Vector},

    # Don't put Vector{Any} here! It breaks on data like: Vector{String} or
    # Vector{Int64}
    path::Vector,

    value::Union{Nothing,Bool,Real,String,Dict,Vector};
    parents::Bool=false,
    candestroy::Bool=false,
    canfilllists::Bool=false,
    listfiller::Function=() -> nothing
)
    setvalue!(
        root,
        Vector{Union{String,VectorIndex}}(path),
        value;
        parents=parents,
        candestroy=candestroy,
        canfilllists=canfilllists,
        listfiller=listfiller
    )
end

end  # module JSONTools
