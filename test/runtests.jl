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

nothing  # Prevent printing the test object in the REPL
