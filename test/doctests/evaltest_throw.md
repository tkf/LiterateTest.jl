# Test `@evaltest_throw`

```@meta
DocTestSetup = quote
    using LiterateTest

    function test(s::AbstractString)
        include_string(@__MODULE__, s)
        return Text(LiterateTest.preprocess(s))
    end
end
```

## `@evaltest_throw` single double-quote

```jldoctest
raw"""
@evaltest_throw "error(1)" begin
    # ignored
end
""" |> test

# output

ans = try # hide
error(1)
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
```

```jldoctest
raw"""
@evaltest_throw "error(\\"1\\")" begin
    # ignored
end
""" |> test

# output

ans = try # hide
error("1")
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
```

## `@evaltest_throw` raw single double-quote

```jldoctest
raw"""
@evaltest_throw raw"error(1)" begin
    # ignored
end
""" |> test

# output

ans = try # hide
error(1)
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
```

```jldoctest
raw"""
@evaltest_throw raw"error(\\"1\\")" begin
    # ignored
end
""" |> test

# output

ans = try # hide
error("1")
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
```

## `@evaltest_throw` triple double-quote

```jldoctest
raw"""
@evaltest_throw \"\"\"error("1")\"\"\" begin
    # ignored
end
""" |> test

# output

ans = try # hide
error("1")
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
```

## `@evaltest_throw` raw triple double-quote

```jldoctest
raw"""
@evaltest_throw raw\"\"\"error("1")\"\"\" begin
    # ignored
end
""" |> test

# output

ans = try # hide
error("1")
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
```

## `@evaltest_throw` using `$` in raw

### single double-quotes

```jldoctest
raw"""
hello = 1
@evaltest_throw raw"error(\\"$hello\\")" begin
    # ignored
end
""" |> test

# output

hello = 1
ans = try # hide
error("$hello")
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
```

### triple double-quotes

```jldoctest
raw"""
hello = 1
@evaltest_throw raw\"\"\"error("$hello")\"\"\" begin
    # ignored
end
""" |> test

# output

hello = 1
ans = try # hide
error("$hello")
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
```
