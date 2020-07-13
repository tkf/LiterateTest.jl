# # [Testing LiterateTest.jl](@id tests)

using Test
using LiterateTest

# This file tests LiterateTest.jl using plain Literate.jl-compatible
# source code.

# ## Removing `ans = begin` and `end`

input = """
    ans = begin
        1 + 2
    end
    """

output = """
    1 + 2
    """

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
