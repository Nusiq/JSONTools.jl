# Exceptions

Currently JSONTools has only one type of exception, `JSONToolsError`. It's thrown only when you try to inserta a value into a JSON structure in a way that is impossible.

Here are some examples:
- Trying to `setindex!` to an object that is not a `Dict` or an `Vector`.
- Trying to `setindex` to a JSON data structure that has a `Dict` root with a path that doesn't start with a `String` key.
- Trying to `setindex!` to a JSON data structure that has a `Vector` root with a path that doesn't start with an `Int` key.
- Trying to `setindex!` to an array that is smaller than the index you're trying to set, without enabling the `canfilllists` option in the path.
- Trying to `setindex!` to a path that is blocked by an existing value, without enabling the `candestroy` option in the path.
- Trying to `setindex!` to a path that requires creating parent objects, without enabling the `parents` option in the path.

```@docs
JSONToolsError
```
