# JSONTools Basics

JSONTools is a Julia package for working with JSON data; it's main goal is to make it easy to access and modify the data structures created by parsing JSON. JSONTools package extends the `Base.getindex` and `Base.setindex!` functions to allow accessing data hidden deep in the JSON structure by providing entire paths to the data without needing to worry about handling errors at each step of the way.

## Installation

The package is not yet registered, so you'll need to install it directly from GitHub.

You can use the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run

```
pkg> add JSONTools
```

## Basic use

The main feature of JSONTools is the `JSONPath` object. It's a path to a value in a JSON structure. It can be used as an index of JSON serializable objects (null, bool, number, string, array, object) for setting and getting values.

The best way to understand how it works is to see it in action. Let's start by parsing some JSON data (this is not part of the package):

```@example basic_use_example
include("../../src/JSONTools.jl")  # hide
using .JSONTools  # hide
import JSON

data = JSON.parse("""
    {
        "a1": {"b": {"c": 1}},
        "a2": {"b": {"c": 2}},
        "a3": {"b": {"c": 3}},
        "x1": [{"y": "A"}, {"y": "B"}, {"y": "C"}],
        "x2": {"y": "D", "b": {"c": 4}}
    }""")
nothing # hide
```

### Getting values

You can access the data using the `JSONPath` object:

```@repl basic_use_example
data[JSONPath("a1" , "b" , "c")]
data[JSONPath("x1", 1, "y")]
```

You can use star patterns to access multiple keys at once (see the [Petterns and Wildcards](@ref patterns_and_wildcards) section for more details):

```@repl basic_use_example
data[JSONPath(star"a*", "b", "c")]
```

You can use values from the `JSONPathWildcard` enum to access multiple values at once (see the [Petterns and Wildcards](@ref patterns_and_wildcards) section for more details):

```@repl basic_use_example
data[JSONPath(ANY_KEY, "b", "c")]
data[JSONPath("x1", ANY_INDEX, "y")]
data[JSONPath(star"x*", SKIP_LIST, "y")]
```

Accessing data that doesn't exist won't throw an error, you'll get a special `EndOfPath` value instead (see the [JSONPath](@ref json_path_object) section for more details):

```@repl basic_use_example
data[JSONPath("this", "data", "doesn't", "exist")]
```


### Setting values

Setting values works in a similar way, except the wildcards and star patterns are not allowed:

```@example basic_use_example
data = JSON.parse("""
    {
        "a1": {"b": {"c": 1}}
    }""")
nothing # hide
```

```@repl basic_use_example
data[JSONPath("a1", "b", "c", candestroy=true)] = 999
data[JSONPath("new", "path", "to", "value", parents=true)] = 123
data[JSONPath("a1", "x", 3, canfilllists=true, parents=true)] = true
JSON.print(data, 4)  # Print entire JSON structure
```
