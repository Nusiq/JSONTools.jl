# The exceptions of the package

"""
JSONToolsError is the base type for all errors from the JSONTools module.
"""
struct JSONToolsError <: Exception
    msg::String
end