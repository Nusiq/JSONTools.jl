# [The JSONPath Object](@id json_path_object)

## JSONPath

```@docs
JSONPath
```

JSONPaths are created using variadic arguments, so you don't need to put your list of keys into a container. JSONPaths can be used for getting and setting the values in a JSON structure.

```@setup json_path_example
include("../../src/JSONTools.jl")
using .JSONTools
```

```@repl json_path_example
myjson = Dict()
mypath = JSONPath("a", "b", "c", parents=true, candestroy=true)
myjson[mypath]
myjson[mypath] = 1
myjson
```

## EndOfPath

```@docs
EndOfPath
```

Example:

```@example end_of_path_example
include("../../src/JSONTools.jl")  # hide
using .JSONTools  # hide
import JSON

data = JSON.parse("""
    {
        "a": {"b": {"c": 1}},
        "b": [1, 2, 3],
        "c": {"d": 1}
    }""")
nothing # hide
```

```@repl end_of_path_example
data[JSONPath("a", "b", "d")]
data[JSONPath("b", 4)]
data[JSONPath("c", "d", "e")]
data[JSONPath(1, "b")]
data1 = 1
data1[JSONPath("a", "b", "c")]

```