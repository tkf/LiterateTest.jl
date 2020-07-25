# # [Testing LiterateTest.jl](@id tests)

using Test
using LiterateTest

# This file tests LiterateTest.jl using plain Literate.jl-compatible
# source code.

# ## Helper function

decode_output(output) = join((strip(ln, '|') for ln in split(output, "\n")), "\n")

@assert decode_output("""
    |a|
    |b|
    """) === """
    a
    b
    """

# ## Removing `ans = begin` and `end`

input = """
    ans = begin
        1 + 2
    end
    """

output = decode_output("""
    |ans = begin # hide|
    |1 + 2|
    |end # hide|
    """)

@assert LiterateTest.preprocess(input) == output

# ## Removing `@testset`

input = """
    @testset begin
        @test 1 + 2 == 3
    end
    """

output = """
    """

@assert LiterateTest.preprocess(input) == output

# Above two patterns can be combined to write tests like this that are
# not visible in the Documenter.jl output:

ans = begin
    1 + 2  # only this line is visible in the documentation
end
@testset begin
    @test ans == 3
end
nothing  # hide

# ## Removing `@test begin` and `end ...`

input = """
    @test begin
        1 + 2
    end == 3
    """

output = """
    1 + 2
    """

@assert LiterateTest.preprocess(input) == output

# When extracting the result of `@test`, it's useful to use `global`.
# However, `global` is not needed when `@test begin ... end` is
# removed.  Thus, `global` is removed from the code as well:

input = """
    @test begin
        global y = 1 + 2
    end == 3
    y + 3
    """

output = """
    y = 1 + 2
    y + 3
    """

@assert LiterateTest.preprocess(input) == output

# `@test` itself can be indented

input = """
    if VERSION >= v"1.4"
        @test begin
            code
        end == 1
    end
    """

output = """
    if VERSION >= v"1.4"
    code
    end
    """

@assert LiterateTest.preprocess(input) == output

# ## Extracting `$code` from `@evaltest "$code"`

input = """
    @evaltest "1 + 2" begin
        @test ans == 3
        @test ans isa Int
    end
    """

output = """
    1 + 2
    """

@assert LiterateTest.preprocess(input) == output

# Note that `"$code"` will be used as the `@testset` title when it's
# evaluated withtout the transformation.

@evaltest "1 + 2" begin
    @test ans == 3
    @test ans isa Int
end
nothing  # hide

# !!! note
#
#     `@evaltest "1 + 2" begin ...` above is shown in this
#     Documenter.jl output because this file is *not* processed by
#     [`LiterateTest.preprocess`](@ref).

#  When using `$` in the code, `raw""` can be useful:

input = raw"""
    x = 1
    @evaltest raw":(1 + $x)" begin
        @test ans == :(1 + $x)
    end
    """

output = raw"""
    x = 1
    :(1 + $x)
    """

@assert LiterateTest.preprocess(input) == output

# Demo:

x = 1
@evaltest raw":(1 + $x)" begin
    @test ans == :(1 + $x)
end
nothing  # hide

# ## Showing error thrown from `$code` in `@evaltest_throw "$code"`

input = """
    @evaltest_throw \"\"\"error("msg")\"\"\" begin
        @test ans == ErrorException(1)
    end
    """

Text(LiterateTest.preprocess(input))

# It's a bit tricky to test this in Literate.jl:

output = decode_output("""
    |ans = try # hide|
    |error("msg")|
    |catch err; err; end # hide|
    |print(stdout, "ERROR: ") # hide|
    |showerror(stdout, ans) # hide|
    |#-|
    """)

@assert LiterateTest.preprocess(input) == output

# Demo:

@evaltest_throw """error("msg")""" begin
    @test ans == ErrorException("msg")
end
nothing  # hide

# ## De-indenting `code` in `@dedent begin code end`

input = """
    @dedent @time begin
        code
    end
    """

output = decode_output("""
    |@time begin # hide|
    |code|
    |end # hide|
    """)

@assert LiterateTest.preprocess(input) == output

# Demo:

@dedent @time begin
    1 + 1
end

# Expressions after `end` are ignored

input = """
    @dedent @assert begin
        code
    end == 1
    """

output = decode_output("""
    |@assert begin # hide|
    |code|
    |end == 1 # hide|
    """)

@assert LiterateTest.preprocess(input) == output

# Demo:

@dedent @assert begin
    1 + 1
end == 2

# `@dedent` works with assignments

input = """
    @dedent y1 = begin
        1 + 1
    end
    @dedent y2 = begin
        3 - 1
    end
    @test y1 == y2
    """

output = decode_output("""
    |y1 = begin # hide|
    |1 + 1|
    |end # hide|
    |y2 = begin # hide|
    |3 - 1|
    |end # hide|
    """)

@assert LiterateTest.preprocess(input) == output

# Demo:

@dedent y1 = begin
    1 + 1
end
@dedent y2 = begin
    3 - 1
end
@test y1 == y2
nothing  # hide

# `@dedent` itself can be indented

input = """
    if VERSION >= v"1.4"
        @dedent @assert begin
            code
        end == 1
    end
    """

output = decode_output("""
    |if VERSION >= v"1.4"|
    |@assert begin # hide|
    |code|
    |end == 1 # hide|
    |end|
    """)

@assert LiterateTest.preprocess(input) == output
