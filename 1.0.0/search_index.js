var documenterSearchIndex = {"docs":
[{"location":"json_path/#json_path_object","page":"The JSONPath Object","title":"The JSONPath Object","text":"","category":"section"},{"location":"json_path/#JSONPath","page":"The JSONPath Object","title":"JSONPath","text":"","category":"section"},{"location":"json_path/","page":"The JSONPath Object","title":"The JSONPath Object","text":"JSONPath","category":"page"},{"location":"json_path/#JSONTools.JSONPath","page":"The JSONPath Object","title":"JSONTools.JSONPath","text":"JSONPath is used to access and set the data in JSON serializable objects using indexing. Below is the list of propertie of the JSONPath object:\n\nProperties that define the path\n\npath - A Tuple of keys and indices that defines the path to the value.\n\nProperties that spefify how to handle inserting data\n\nparents - If true, the path will be created if it doesn't exist.\ncandestroy - If true, the path will be overwritten if it exists (including the parent values that are in the way).\ncanfilllists - If true, the path will be created if it doesn't exist and the lists will be filled with the listfiller function.\nlistfiller - This function is used to fill the lists when canfilllists is true.\n\n\n\n\n\n","category":"type"},{"location":"json_path/","page":"The JSONPath Object","title":"The JSONPath Object","text":"JSONPaths are created using variadic arguments, so you don't need to put your list of keys into a container. JSONPaths can be used for getting and setting the values in a JSON structure.","category":"page"},{"location":"json_path/","page":"The JSONPath Object","title":"The JSONPath Object","text":"include(\"../../src/JSONTools.jl\")\nusing .JSONTools","category":"page"},{"location":"json_path/","page":"The JSONPath Object","title":"The JSONPath Object","text":"myjson = Dict()\nmypath = JSONPath(\"a\", \"b\", \"c\", parents=true, candestroy=true)\nmyjson[mypath]\nmyjson[mypath] = 1\nmyjson","category":"page"},{"location":"json_path/#EndOfPath","page":"The JSONPath Object","title":"EndOfPath","text":"","category":"section"},{"location":"json_path/","page":"The JSONPath Object","title":"The JSONPath Object","text":"EndOfPath","category":"page"},{"location":"json_path/#JSONTools.EndOfPath","page":"The JSONPath Object","title":"JSONTools.EndOfPath","text":"EndOfPath represents an error that occured during access to a JSON path. EndOfPath is not an exception. It's just an enum with a few values which may be useful for further processing.\n\nFields\n\nMISSING_KEY - The requested key of an object is missing.\nOUT_OF_BOUNDS - The requested index of a list is out of bounds.\nNOT_A_CONTAINER - Requested access to an object which is not an object or a list.\nINVALID_KEY_TYPE - Requested access to an object using index or to a list using a key.\nINVALID_ROOT - The root object is not a Dict or a Vector. The errors that occure in the root object are separated because the setindex! function isn't able to modify the root object so the user might want to handle them in a different way.\n\n\n\n\n\n","category":"type"},{"location":"json_path/","page":"The JSONPath Object","title":"The JSONPath Object","text":"Example:","category":"page"},{"location":"json_path/","page":"The JSONPath Object","title":"The JSONPath Object","text":"include(\"../../src/JSONTools.jl\")  # hide\nusing .JSONTools  # hide\nimport JSON\n\ndata = JSON.parse(\"\"\"\n    {\n        \"a\": {\"b\": {\"c\": 1}},\n        \"b\": [1, 2, 3],\n        \"c\": {\"d\": 1}\n    }\"\"\")\nnothing # hide","category":"page"},{"location":"json_path/","page":"The JSONPath Object","title":"The JSONPath Object","text":"data[JSONPath(\"a\", \"b\", \"d\")]\ndata[JSONPath(\"b\", 4)]\ndata[JSONPath(\"c\", \"d\", \"e\")]\ndata[JSONPath(1, \"b\")]\ndata1 = 1\ndata1[JSONPath(\"a\", \"b\", \"c\")]\n","category":"page"},{"location":"patterns_and_wildcards/#patterns_and_wildcards","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"","category":"section"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"There are two ways of accessing multiple JSON paths at once using the JSONTools package - Wildcards and Star patterns.","category":"page"},{"location":"patterns_and_wildcards/#Wildcards","page":"Patterns and Wildcards","title":"Wildcards","text":"","category":"section"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"Wildcards are used in common cases when you want to access multiple values at once.","category":"page"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"JSONPathWildcard","category":"page"},{"location":"patterns_and_wildcards/#JSONTools.JSONPathWildcard","page":"Patterns and Wildcards","title":"JSONTools.JSONPathWildcard","text":"Wildcards are used to match multiple keys or indices in a JSON path at once. There are four types of wildcards:\n\nANY_KEY - Matches any key in a Dict.\nANY_INDEX - Matches any index in a Vector.\nANY - Matches any key or in a Dict or index in a Vector.\nSKIP_LIST - If current value in the path is a Vector, matches all indices. If the current value is not a Vector it has no effect except for packing current value into a result Tuple with one element.\n\nThe wildcards can only be used for reading data, not for setting it.\n\n\n\n\n\n","category":"type"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"The SKIP_LIST wildcard might not be obvious at first, so here are some examples:","category":"page"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"include(\"../../src/JSONTools.jl\")  # hide\nusing .JSONTools  # hide\n# Setup\nimport JSON\n\ndata = JSON.parse(\"\"\"\n    {\n        \"a1\": [\n            {\"b\": \"X\"},\n            {\"b\": \"Y\"},\n            {\"b\": \"Z\"}\n        ],\n        \"a2\": {\"b\": \"A\"}\n    }\"\"\")\nnothing # hide","category":"page"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"data[JSONPath(\"a1\", SKIP_LIST, \"b\")]  # enters the list\ndata[JSONPath(\"a2\", SKIP_LIST, \"b\")]  # no effect\ndata[JSONPath(\"a1\", ANY_INDEX, \"b\")]  # using ANY_INDEX for the same effect","category":"page"},{"location":"patterns_and_wildcards/#Star-patterns","page":"Patterns and Wildcards","title":"Star patterns","text":"","category":"section"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"Starn patterns are like wildcards, but they give you more control over which values you want to access. Star patterns are only used for keys, not for indices.","category":"page"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"StarPattern","category":"page"},{"location":"patterns_and_wildcards/#JSONTools.StarPattern","page":"Patterns and Wildcards","title":"JSONTools.StarPattern","text":"StarPattern is a custom string created with the start_str macro. It is used for matching text with a pattern that uses \"*\" as a wildcard against Strings.\n\nUnlike regular String objects StarPattern strings can be indexed by the character position.\n\n\n\n\n\n","category":"type"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"Pattern matching is done using the starmatch function:","category":"page"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"starmatch","category":"page"},{"location":"patterns_and_wildcards/#JSONTools.starmatch","page":"Patterns and Wildcards","title":"JSONTools.starmatch","text":"starmatch(text::String, pattern::StarPattern)\n\nMatch the text with a pattern that uses \"*\" as a wildcard which can represent any number of characters.\n\n\n\n\n\n","category":"function"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"The main use case for star patterns is using them in JSONPath objects, but you can use them anywhere you want:","category":"page"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"include(\"../../src/JSONTools.jl\")\nusing .JSONTools","category":"page"},{"location":"patterns_and_wildcards/","page":"Patterns and Wildcards","title":"Patterns and Wildcards","text":"starmatch(\"This is a message\", star\"This*\")\nstarmatch(\"This is a message\", star\"XXX*\")\nstarmatch(\"This is a message\", star\"*is*\")","category":"page"},{"location":"#JSONTools-Basics","page":"JSONTools Basics","title":"JSONTools Basics","text":"","category":"section"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"JSONTools is a Julia package for working with JSON data; it's main goal is to make it easy to access and modify the data structures created by parsing JSON. JSONTools package extends the Base.getindex and Base.setindex! functions to allow accessing data hidden deep in the JSON structure by providing entire paths to the data without needing to worry about handling errors at each step of the way.","category":"page"},{"location":"#Installation","page":"JSONTools Basics","title":"Installation","text":"","category":"section"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"The package is not yet registered, so you'll need to install it directly from GitHub.","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"You can use the Julia package manager. From the Julia REPL, type ] to enter the Pkg REPL mode and run","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"pkg> add JSONTools","category":"page"},{"location":"#Basic-use","page":"JSONTools Basics","title":"Basic use","text":"","category":"section"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"The main feature of JSONTools is the JSONPath object. It's a path to a value in a JSON structure. It can be used as an index of JSON serializable objects (null, bool, number, string, array, object) for setting and getting values.","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"The best way to understand how it works is to see it in action. Let's start by parsing some JSON data (this is not part of the package):","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"include(\"../../src/JSONTools.jl\")  # hide\nusing .JSONTools  # hide\nimport JSON\n\ndata = JSON.parse(\"\"\"\n    {\n        \"a1\": {\"b\": {\"c\": 1}},\n        \"a2\": {\"b\": {\"c\": 2}},\n        \"a3\": {\"b\": {\"c\": 3}},\n        \"x1\": [{\"y\": \"A\"}, {\"y\": \"B\"}, {\"y\": \"C\"}],\n        \"x2\": {\"y\": \"D\", \"b\": {\"c\": 4}}\n    }\"\"\")\nnothing # hide","category":"page"},{"location":"#Getting-values","page":"JSONTools Basics","title":"Getting values","text":"","category":"section"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"You can access the data using the JSONPath object:","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"data[JSONPath(\"a1\" , \"b\" , \"c\")]\ndata[JSONPath(\"x1\", 1, \"y\")]","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"You can use star patterns to access multiple keys at once (see the Petterns and Wildcards section for more details):","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"data[JSONPath(star\"a*\", \"b\", \"c\")]","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"You can use values from the JSONPathWildcard enum to access multiple values at once (see the Petterns and Wildcards section for more details):","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"data[JSONPath(ANY_KEY, \"b\", \"c\")]\ndata[JSONPath(\"x1\", ANY_INDEX, \"y\")]\ndata[JSONPath(star\"x*\", SKIP_LIST, \"y\")]","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"Accessing data that doesn't exist won't throw an error, you'll get a special EndOfPath value instead (see the JSONPath section for more details):","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"data[JSONPath(\"this\", \"data\", \"doesn't\", \"exist\")]","category":"page"},{"location":"#Setting-values","page":"JSONTools Basics","title":"Setting values","text":"","category":"section"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"Setting values works in a similar way, except the wildcards and star patterns are not allowed:","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"data = JSON.parse(\"\"\"\n    {\n        \"a1\": {\"b\": {\"c\": 1}}\n    }\"\"\")\nnothing # hide","category":"page"},{"location":"","page":"JSONTools Basics","title":"JSONTools Basics","text":"data[JSONPath(\"a1\", \"b\", \"c\", candestroy=true)] = 999\ndata[JSONPath(\"new\", \"path\", \"to\", \"value\", parents=true)] = 123\ndata[JSONPath(\"a1\", \"x\", 3, canfilllists=true, parents=true)] = true\nJSON.print(data, 4)  # Print entire JSON structure","category":"page"},{"location":"exceptions/#Exceptions","page":"Exceptions","title":"Exceptions","text":"","category":"section"},{"location":"exceptions/","page":"Exceptions","title":"Exceptions","text":"Currently JSONTools has only one type of exception, JSONToolsError. It's thrown only when you try to inserta a value into a JSON structure in a way that is impossible.","category":"page"},{"location":"exceptions/","page":"Exceptions","title":"Exceptions","text":"Here are some examples:","category":"page"},{"location":"exceptions/","page":"Exceptions","title":"Exceptions","text":"Trying to setindex! to an object that is not a Dict or an Vector.\nTrying to setindex to a JSON data structure that has a Dict root with a path that doesn't start with a String key.\nTrying to setindex! to a JSON data structure that has a Vector root with a path that doesn't start with an Int key.\nTrying to setindex! to an array that is smaller than the index you're trying to set, without enabling the canfilllists option in the path.\nTrying to setindex! to a path that is blocked by an existing value, without enabling the candestroy option in the path.\nTrying to setindex! to a path that requires creating parent objects, without enabling the parents option in the path.","category":"page"},{"location":"exceptions/","page":"Exceptions","title":"Exceptions","text":"JSONToolsError","category":"page"},{"location":"exceptions/#JSONTools.JSONToolsError","page":"Exceptions","title":"JSONTools.JSONToolsError","text":"JSONToolsError is the base type for all errors from the JSONTools module.\n\n\n\n\n\n","category":"type"}]
}
