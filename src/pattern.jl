# Custom starpattern string for pattern matching in JSONPath

"""
StarPattern is a custom string created with the start_str macro. It is used
for matching text with a pattern that uses "*" as a wildcard against Strings.

Unlike regular String objects StarPattern strings can be indexed by the
character position.
"""
struct StarPattern <: AbstractString
    data::Tuple{Vararg{Char}}
end

Base.show(io::IO, pattern::StarPattern) = print(io, join(pattern.data))
Base.ncodeunits(pattern::StarPattern) = length(pattern.data)
Base.codeunit(pattern::StarPattern, i::Int) = pattern.data[i]
Base.isvalid(pattern::StarPattern, i::Int64) = 1 <= i <= length(pattern.data)
Base.iterate(pattern::StarPattern, i::Int64=1) = i > length(pattern.data) ? nothing : (pattern.data[i], i+1)

macro star_str(s::String)
    return StarPattern(Tuple{Vararg{Char}}(s))
end

"""
Matches text with a pattern that uses "*" as a wildcard which
can represent any number of characters.

:param pattern: the pattern
:param text: the text being matched with pattern
"""
function starmatch(text::String, pattern::StarPattern)::Bool
    # Change into tuples of unicode characters to allow indexing by the
    # character position
    textchars = Tuple(text)
    lenp, lent = length(pattern), length(textchars)


    # Only empty text can match empty pattern
    if lenp == 0
        return lent == 0
    end
    # The table that represents matching smaller patterns to
    # parts of the text. Row 0 is for empty pattern, column 0
    # represents empty text: matches[text+1][pattern+1]
    matches = fill(false, lent + 1, lenp + 1)
    # Empty pattern matches the empty string
    matches[1, 1] = true

    # Only paterns made out of '*' can match empty stirng
    for p in 1:lenp
        # Propagate matching apttern as long as long as the
        # pattern uses only '*'
        if pattern[p] == '*'
            matches[1, p+1] = matches[1, p]
        else
            break
        end
    end
    # Fill the pattern matching table (solutions to
    # shorter patterns/texts are used to solve
    # other patterns with increasing complexity).
    for t in 1:lent
        for p in 1:lenp
            if pattern[p] == '*'
                # Two wys to propagate matching value
                # A) Same pattern without '*' worked so this also works
                # B) Shorter text matched this pattern, and it ends with '*'
                # so adding characters doesn't change anything
                matches[t+1, p+1] = (
                    matches[t+1, p] ||
                    matches[t, p+1]
                )
            elseif pattern[p] == textchars[t]
                # One way to propagate matching value
                # If the pattern with one less character matched the text
                # with one less character (and we have a matching pair now)
                # then this pattern also matches
                matches[t+1, p+1] = matches[t, p]
            else
                matches[t+1, p+1] = false  # no match, always false
            end
        end
    end
    return matches[lent+1, lenp+1]  # return last matched pattern
end