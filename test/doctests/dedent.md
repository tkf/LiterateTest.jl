# Test `@dedent`

```@meta
DocTestSetup = quote
    using LiterateTest

    function test(s::AbstractString)
        include_string(@__MODULE__, s)
        return Text(LiterateTest.preprocess(s))
    end
end
```

## `@dedent` with just `begin ... end`

```jldoctest
raw"""
@dedent begin
    1 + 1
end
""" |> test

# output

begin # hide
1 + 1
end # hide
```

## `@dedent` with a macro

```jldoctest
raw"""
@dedent @dedent begin
    1 + 1
end
""" |> test

# output

@dedent begin # hide
1 + 1
end # hide
```

## `@dedent` with code after `end`

```jldoctest
raw"""
@dedent @assert begin
    1 + 1
end == 2
""" |> test

# output

@assert begin # hide
1 + 1
end == 2 # hide
```

## `@dedent` with `global`

```jldoctest
raw"""
@dedent begin
    global x = 1
end
""" |> test

# output

begin # hide
x = 1
end # hide
```

## `@dedent` with `global` and newline

```jldoctest
raw"""
@dedent begin
    global x =
        1
end
""" |> test

# output

begin # hide
x =
    1
end # hide
```
