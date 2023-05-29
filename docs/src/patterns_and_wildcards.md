# [Patterns and Wildcards](@id patterns_and_wildcards)

There are two ways of accessing multiple JSON paths at once using the JSONTools package - Wildcards and Star patterns.

## Wildcards

Wildcards are used in common cases when you want to access multiple values at once.

```@docs
JSONPathWildcard
```

The `SKIP_LIST` wildcard might not be obvious at first, so here are some examples:

```@example wildcards_example
include("../../src/JSONTools.jl")  # hide
using .JSONTools  # hide
# Setup
import JSON

data = JSON.parse("""
    {
        "a1": [
            {"b": "X"},
            {"b": "Y"},
            {"b": "Z"}
        ],
        "a2": {"b": "A"}
    }""")
nothing # hide
```

```@repl wildcards_example
data[JSONPath("a1", SKIP_LIST, "b")]  # enters the list
data[JSONPath("a2", SKIP_LIST, "b")]  # no effect
data[JSONPath("a1", ANY_INDEX, "b")]  # using ANY_INDEX for the same effect
```


## Star patterns

Starn patterns are like wildcards, but they give you more control over which values you want to access. Star patterns are only used for keys, not for indices.

```@docs
StarPattern
```

Pattern matching is done using the `starmatch` function:

```@docs
starmatch
```

The main use case for star patterns is using them in `JSONPath` objects, but you can use them anywhere you want:

```@setup starmatch_example
include("../../src/JSONTools.jl")
using .JSONTools
```

```@repl starmatch_example
starmatch("This is a message", star"This*")
starmatch("This is a message", star"XXX*")
starmatch("This is a message", star"*is*")
```