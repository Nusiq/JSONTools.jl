using JSONTools
import JSON
using Test

@testset "Get values from JSON path" begin

    data = JSON.parse("""
        {
            "a": {"b": {"c": 1}},
            "x": [{"y": 2}]
        }""")
    # Valid access
    result = data[JSONPath("a" , "b" , "c")]
    @test result == 1

    result = data[JSONPath("x", 1, "y")]
    @test result == 2

    # Invalid key type
    result = data[JSONPath("a", 1)]
    @test result == INVALID_KEY_TYPE::EndOfPath
    result = data[JSONPath("x", "b")]
    @test result == INVALID_KEY_TYPE::EndOfPath

    # Missing key / index out of bounds
    result = data[JSONPath("a", "B")]
    @test result == MISSING_KEY::EndOfPath

    result = data[JSONPath("x", 2)]
    @test result == OUT_OF_BOUNDS::EndOfPath

    # Invalid root
    result = 1[JSONPath("a")]
    @test result == INVALID_ROOT::EndOfPath

    # Access to a non-container
    result = data[JSONPath("a", "b", "c", "d")]
    @test result == NOT_A_CONTAINER::EndOfPath

    # Propagate an error
    result = 1[JSONPath("a", 1, "b", "c")]
    @test result == INVALID_ROOT::EndOfPath
end

@testset "Set value using JSON path" begin
    data = JSON.parse("""
            {
                "a": {"b": {"c": 1}},
                "x": [{"y": 2}]
            }""")

    # DICTIONARY ACCESS
    # Set new value
    path = JSONPath("a", "b", "c1")
    data[path] = 99
    @test data[path] == 99

    # Overwrite existing value
    path = JSONPath("a", "b", "c", candestroy=true)
    data[path] = 88
    @test data[path] == 88

    # Create completely new branch
    path = JSONPath("A", "B", "C", parents=true)
    data[path] = 77
    @test data[path] == 77

    # Break existing branch
    path = JSONPath("A", "B", "C", "D", parents=true, candestroy=true)
    data[path] = 66
    @test data[path] == 66

    # Change a value in the root
    path = JSONPath("A", parents=true, candestroy=true)
    data[path] = 55
    @test data[path] == 55


    # LIST ACCESS
    # Create a new branch with a list (should fill with null values)
    path = JSONPath("X", 3, "Y", parents=true, canfilllists=true)
    data[path] = 44
    @test data[path] == 44
    @test data[JSONPath("X", 2)] === nothing
    @test data[JSONPath("X", 1)] === nothing

    # Replace a value in a list
    path = JSONPath("X", 3, candestroy=true)
    data[path]  = 33
    @test data[path] == 33

    # Custom list fillter
    path = JSONPath(
        "X", 5,
        parents=true,
        canfilllists=true,
        listfiller=() -> "Hello")
    data[path] = 22
    @test data[JSONPath("X", 5)] == 22
    @test data[JSONPath("X", 4)] == "Hello"
    @test data[JSONPath("X", 3)] == 33  # From previous test

    # println(JSON.json(data))
end

@testset "Set value JSONPath (invalid)" begin
    data = JSON.parse("""
            {
                "a": {"b": {"c": 1}},
                "x": [{"y": 2}, 11, 22]
            }""")

    # Can't make parents (parents=false by default)
    @test_throws JSONToolsError data[JSONPath("A", "B")] = 99

    # Can't destroy (candestroy=false by default)
    @test_throws JSONToolsError data[JSONPath("a", "b", "c")] = 99

    # Can't fill lists (canfilllists=false by default)
    @test_throws JSONToolsError data[JSONPath("x", 4, "y")] = 99

    # Fill list just to make sure it works
    path = JSONPath("x", 4, "y", canfilllists=true)
    data[path] = 99
    @test data[path] == 99
end

@testset "Get values using paths with JSONPathWildcard" begin
    data = JSON.parse("""
        {
            "a": {
                "b1": {
                    "c": 1,
                    "d": {
                        "e1": 1,
                        "e2": 11
                    },
                    "f": 1
                },
                "b2": {
                    "c": 2,
                    "d": {
                        "e1": 2,
                        "e2": 22
                    },
                    "f": 2
                },
                "b3": {
                    "c": 3,
                    "d": {
                        "e1": 3,
                        "e2": 33
                    }
                }
            },
            "b": [{ "c": 1 }, { "c": 2 }, { "c": 3 }]
        }""")
    # Tests are collected and sorted because
    cs = (x) -> x |> collect |> sort

    # ANY_KEY
    result = data[JSONPath("a", ANY_KEY, "c")]
    @test result isa Tuple
    @test cs(result) == cs([1, 2, 3])
    
    # ANY
    result = data[JSONPath("a", ANY, "c")]
    @test result isa Tuple
    @test cs(result) == cs([1, 2, 3])

    # ANY_INDEX
    result = data[JSONPath("b", ANY_INDEX, "c")]
    @test result isa Tuple
    @test cs(result) == cs([1, 2, 3])

    # Nested
    result = data[JSONPath("a", ANY_KEY, "d", ANY_KEY)]
    @test result isa Tuple
    @test cs(result) == cs([1, 11, 2, 22, 3, 33])

    # Missing path - the 'f' key is in 'b1' and 'b2' but not in 'b3'
    result = data[JSONPath("a", ANY_KEY, "f")]
    @test result isa Tuple
    @test cs(result) == cs([1, 2])

    # WARNING! The results of 2 next tests might feel counterintuitive
    # Wrong path strting with wildcards: Return empty tuple
    result = data[JSONPath(ANY_KEY, "yyy")]
    @test result isa Tuple
    @test length(result) == 0
    # Wrong path starting with wrong key: Returns EndOfPath
    result = data[JSONPath("yyy", ANY_KEY)]
    @test result == MISSING_KEY::EndOfPath

    # SKIP_LIST skipping the list like ANY_INDEX
    result = data[JSONPath("b", SKIP_LIST, "c")]
    @test result isa Tuple
    @test cs(result) == cs([1, 2, 3])

    # SKIP_LIST do nothing because result is not a list (changes result to
    # tuple)
    result = data[JSONPath("a", SKIP_LIST, SKIP_LIST, SKIP_LIST, "b1", "c")]
    @test result isa Tuple
    @test cs(result) == cs([1])

    # SKIP_LIST change primitive to tuple
    # Test without SKIP_LIST
    result = data[JSONPath("a", "b1", "c")]
    @test result == 1
    # Test with SKIP_LIST
    result = data[JSONPath("a", "b1", "c", SKIP_LIST)]
    @test result isa Tuple
    @test cs(result) == cs([1])

    # Accessing EndOfPath with a wildcard returns INVALID_ROOT error
    result = (INVALID_KEY_TYPE::EndOfPath)[JSONPath(ANY_KEY::JSONPathWildcard)]
    @test result == INVALID_ROOT::EndOfPath
end

@testset "Try to set vaues using wildcards/star patterns" begin
    data = JSON.parse("""
        {
            "a": {"b": {"c": 1}},
            "x": [{"y": 2}, 11, 22]
        }""")
    # Setting values with wildcards is not supported
    @test_throws JSONToolsError data[JSONPath(ANY, "B")] = 99
    @test_throws JSONToolsError data[JSONPath("a", ANY)] = 99
    @test_throws JSONToolsError data[JSONPath("a", ANY, "c")] = 99
    # Setting value with star patterns is not supported
    @test_throws JSONToolsError data[JSONPath(star"*", "B")] = 88
    @test_throws JSONToolsError data[JSONPath("a", star"*")] = 88
    @test_throws JSONToolsError data[JSONPath("a", star"*", "c")] = 88
end

@testset "Test StarPattern match" begin
    @test starmatch("żółć", star"żółć")
    @test starmatch("żółć", star"ż*")
    @test starmatch("żółć", star"*ć")
    @test starmatch("żółć", star"ż*ć")
    @test starmatch("some long text", star"s*e long t*t")
    @test starmatch("some long text", star"s***t")
    @test starmatch("some long text", star"***t")
    @test starmatch("some long text", star"s***")
    @test starmatch("some long text", star"***")
end

@testset "Get values using paths with StarPatterns" begin
    data = JSON.parse("""
            {
                "a1": {
                    "b": 1,
                    "cPc": {"dd": 11}
                },
                "a2": {
                    "b": 2,
                    "cQc": {"dd": 22}
                },
                "a3": {
                    "b": 3,
                    "cRc": {"dd": 33}
                },
                "b1": {
                    "b": 4,
                    "cSc": {"dd": 44}
                }
            }""")
    # Tests are collected and sorted because
    cs = (x) -> x |> collect |> sort

    # Match everything
    result = data[JSONPath(star"*", "b")]
    @test result isa Tuple
    @test cs(result) == cs([1, 2, 3, 4])

    # Match A's
    result = data[JSONPath(star"a*", "b")]
    @test result isa Tuple
    @test cs(result) == cs([1, 2, 3])

    # Match pattern in the middle
    result = data[JSONPath(star"*", star"c*c", "dd")]
    @test result isa Tuple
    @test cs(result) == cs([11, 22, 33, 44])
end

nothing  # Prevent printing the test object in the REPL
