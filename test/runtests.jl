using JSONTools
import JSON
using Test

@testset "Quick JSON path access" begin
    data = JSON.parse("""
        {
            "a": {"b": {"c": 1}},
            "x": [{"y": 2}]
        }""")

    # QUICK ACCESS TEST
    (/) = quickaccessjson
    # Valid access
    @test (data / "a" / "b" / "c") == 1
    @test (data / "x" / 1 / "y") == 2

    # Invalid key type
    @test (data / "a" / 1) == INVALID_KEY_TYPE::EndOfPath
    @test (data / "x" / "b") == INVALID_KEY_TYPE::EndOfPath

    # Missing key / index out of bounds
    @test (data / "a" / "B") == MISSING_KEY::EndOfPath
    @test (data / "x" / 2) == OUT_OF_BOUNDS::EndOfPath

    # Access to a non-container
    @test (1 / "a") == NOT_A_CONTAINER::EndOfPath
    @test (data / "a" / "b" / "c" / "d") == NOT_A_CONTAINER::EndOfPath

    # Propagate an error
    @test (1 / "a" / 1 / "b" / "c") == NOT_A_CONTAINER::EndOfPath
end

@testset "Tracked JSON path access" begin

    data = JSON.parse("""
        {
            "a": {"b": {"c": 1}},
            "x": [{"y": 2}]
        }""")
    # QUICK ACCESS TEST
    (/) = trackedaccessjson
    # Valid access
    path = data / "a" / "b" / "c"
    @test path.value == 1
    @test path.path == ["a", "b", "c"]

    path = data / "x" / 1 / "y"
    @test path.value == 2
    @test path.path == ["x", 1, "y"]

    # Invalid key type
    path = data / "a" / 1
    @test path.value == INVALID_KEY_TYPE::EndOfPath
    @test path.path == ["a", 1]
    path = data / "x" / "b"
    @test path.value == INVALID_KEY_TYPE::EndOfPath
    @test path.path == ["x", "b"]

    # Missing key / index out of bounds
    path = data / "a" / "B"
    @test path.value == MISSING_KEY::EndOfPath
    @test path.path == ["a", "B"]

    path = data / "x" / 2
    @test path.value == OUT_OF_BOUNDS::EndOfPath
    @test path.path == ["x", 2]

    # Invalid root
    path = 1 / "a"
    @test path.value == INVALID_ROOT::EndOfPath
    @test path.path == ["a"]

    # Access to a non-container
    path = data / "a" / "b" / "c" / "d"
    @test path.value == NOT_A_CONTAINER::EndOfPath
    @test path.path == ["a", "b", "c", "d"]

    # Propagate an error
    path = 1 / "a" / 1 / "b" / "c"
    @test path.value == INVALID_ROOT::EndOfPath
    @test path.path == ["a", 1, "b", "c"]
end

@testset "Set value JSONPath (valid)" begin
    data = JSON.parse("""
            {
                "a": {"b": {"c": 1}},
                "x": [{"y": 2}]
            }""")
    (/) = trackedaccessjson
    (//) = quickaccessjson

    # DICTIONARY ACCESS
    # Set new value
    setvalue!(data / "a" / "b" / "c1", 99)
    @test (data // "a" // "b" // "c1") == 99

    # Overwrite existing value
    setvalue!(data / "a" / "b" / "c", 88, candestroy=true)
    @test (data // "a" // "b" // "c") == 88

    # Create completely new branch
    setvalue!(data / "A" / "B" / "C", 77, parents=true)
    @test (data // "A" // "B" // "C") == 77

    # Break existing branch
    setvalue!(data / "A" / "B" / "C" / "D", 66, parents=true, candestroy=true)
    @test (data // "A" // "B" // "C" // "D") == 66

    # Change a value in the root
    setvalue!(data / "A", 55, parents=true, candestroy=true)
    @test (data // "A") == 55


    # LIST ACCESS
    # Create a new branch with a list (should fill with null values)
    setvalue!(data / "X" / 3 / "Y", 44, parents=true, canfilllists=true)
    @test (data // "X" // 3 // "Y") == 44
    @test (data // "X" // 2) === nothing
    @test (data // "X" // 1) === nothing

    # Replace a value in a list
    setvalue!(data / "X" / 3, 33, candestroy=true)
    @test (data // "X" // 3) == 33

    # Custom list fillter
    setvalue!(
        data / "X" / 5,
        22,
        parents=true,
        canfilllists=true,
        listfiller=() -> "Hello")
    @test (data // "X" // 5) == 22
    @test (data // "X" // 4) == "Hello"
    @test (data // "X" // 3) == 33  # From previous test

    # println(JSON.json(data))
end

@testset "Set value JSONPath (invalid)" begin
    data = JSON.parse("""
            {
                "a": {"b": {"c": 1}},
                "x": [{"y": 2}, 11, 22]
            }""")
    (/) = trackedaccessjson
    (//) = quickaccessjson

    # Can't make parents (parents=false by default)
    @test_throws JSONToolsError setvalue!(data / "A" / "B", 99)

    # Can't destroy (candestroy=false by default)
    @test_throws JSONToolsError setvalue!(data / "a" / "b" / "c", 99)

    # Can't fill lists (canfilllists=false by default)
    @test_throws JSONToolsError setvalue!(data / "x" / 4 / "y", 99)

    # Fill list just to make sure it works
    setvalue!(data / "x" / 4 / "y", 99, canfilllists=true)
    @test (data // "x" // 4 // "y") == 99
end

@testset "Set value root + vector path (valid)" begin
    data = JSON.parse("""
            {
                "a": {"b": {"c": 1}},
                "x": [{"y": 2}]
            }""")
    (/) = trackedaccessjson
    (//) = quickaccessjson

    # DICTIONARY ACCESS
    # Set new value
    setvalue!(data, ["a", "b", "c1"], 99)
    @test (data // "a" // "b" // "c1") == 99

    # Overwrite existing value
    setvalue!(data, ["a" ,"b" ,"c"], 88, candestroy=true)
    @test (data // "a" // "b" // "c") == 88

    # Create completely new branch
    setvalue!(data, ["A", "B", "C"], 77, parents=true)
    @test (data // "A" // "B" // "C") == 77

    # Break existing branch
    setvalue!(data, ["A", "B", "C", "D"], 66, parents=true, candestroy=true)
    @test (data // "A" // "B" // "C" // "D") == 66

    # Change a value in the root
    setvalue!(data, ["A",], 55, parents=true, candestroy=true)
    @test (data // "A") == 55


    # LIST ACCESS
    # Create a new branch with a list (should fill with null values)
    setvalue!(data, ["X", 3, "Y"], 44, parents=true, canfilllists=true)
    @test (data // "X" // 3 // "Y") == 44
    @test (data // "X" // 2) === nothing
    @test (data // "X" // 1) === nothing

    # Replace a value in a list
    setvalue!(data, ["X", 3], 33, candestroy=true)
    @test (data // "X" // 3) == 33

    # Custom list fillter
    setvalue!(
        data, ["X", 5],
        22,
        parents=true,
        canfilllists=true,
        listfiller=() -> "Hello")
    @test (data // "X" // 5) == 22
    @test (data // "X" // 4) == "Hello"
    @test (data // "X" // 3) == 33  # From previous test

    # println(JSON.json(data))
end

@testset "Set value root + vector path (invalid)" begin
    data = JSON.parse("""
            {
                "a": {"b": {"c": 1}},
                "x": [{"y": 2}, 11, 22]
            }""")
    (/) = trackedaccessjson
    (//) = quickaccessjson

    # Can't make parents (parents=false by default)
    @test_throws JSONToolsError setvalue!(data, ["A", "B"], 99)

    # Can't destroy (candestroy=false by default)
    @test_throws JSONToolsError setvalue!(data, ["a", "b", "c"], 99)

    # Can't fill lists (canfilllists=false by default)
    @test_throws JSONToolsError setvalue!(data, ["x", 4, "y"], 99)

    # Fill list just to make sure it works
    setvalue!(data, ["x", 4, "y"], 99, canfilllists=true)
    @test (data // "x" // 4 // "y") == 99
end

nothing  # Prevent printing the test object in the REPL
