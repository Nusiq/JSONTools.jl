# 1.0.0
- The first released version of the package.
- Supports custom `getindex` and `setindex!` methods for JSON serializable objects.
- Supports splitting paths using `JSONPathWildcard` enum that includes following values:
    - ANY_KEY
    - ANY_INDEX
    - ANY
    - SKIP_LIST
- Supports the star patterns created using `star_str` macro.
