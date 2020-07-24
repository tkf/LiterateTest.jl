module LiterateTest

export @evaltest, @evaltest_throw

import Test

"""
    LiterateTest.config(; overloads...) -> config::Dict{Symbol,Ans}

Construct a `config` dictionary that can be passed to
`Literate.markdown` etc.

`LiterateTest.config` post-composes given `preprocess` function
(default: `identity`) with `LiterateTest.preprocess`.
"""
config(; preprocess = identity, kw...) =
    Dict{Symbol,Any}(:preprocess => (@__MODULE__).preprocess ∘ preprocess, kw...)

nitems(itr) = count(_ -> true, itr)

if isdefined(Iterators, :takewhile)
    using Base.Iterators: takewhile
else
    takewhile(pred, xs) = TakeWhile(pred, xs)
    struct TakeWhile{I,P<:Function}
        pred::P
        xs::I
    end
    function Base.iterate(ibl::TakeWhile, itr...)
        y = iterate(ibl.xs, itr...)
        y === nothing && return nothing
        ibl.pred(y[1]) || return nothing
        y
    end
    Base.IteratorSize(::Type{<:TakeWhile}) = Base.SizeUnknown()
    Base.IteratorEltype(::Type{TakeWhile{I,P}}) where {I,P} = Base.IteratorEltype(I)
end

#! format: off
const INTERPOLATION_NOT_SUPPORTED_ERROR = ArgumentError(
    raw"""
    Interpolation with `$` is not supported.
    Use `raw"..."` to avoid parsing `$` as interpolation.
    """
)
#! format: on

"""
    LiterateTest.preprocess(code::AbstractString) -> code′::String

Remove testing related code from `code`.

See [Testing LiterateTest.jl](@ref tests) for examples of how it works.

!!! note

    Currently, `LiterateTest.preprocess` is implemented as a plain
    line-based transformation.  It may break with complex expressions.

`LiterateTest.preprocess` does the following transformations:

* Remove `ans = begin` and `end` from

  ```
  ans = begin
      # any number of lines with consistent indentation
  end
  ```

  and then de-indent the lines inside `begin ... end`.

* Remove `@test begin` and `end ...` from

  ```
  @test begin
      # any number of lines with consistent indentation
  end # any content after `end` is ignored.
  ```

  and then de-indent the lines inside `begin ... end`.  Also remove
  `global` from assignments of the form `global ... = ...` if appears
  at the shallowest indentation level.

* Remove the `@testset` block of the form

  ```
  @testset ...
      ...
  end
  ```

* Extract `\$code` from

  ```
  @evaltest "\$code" ...
      ...
  end
  ```

  and remove everything else.
"""
function preprocess(original::AbstractString)
    source = Iterators.Stateful(eachline(IOBuffer(original)))
    io = IOBuffer()
    while true
        ln = try
            popfirst!(source)
        catch
            break
        end
        if ln == "ans = begin"
            print_deindent_until(io, source) do ln
                ln == "end"
            end
        elseif ln == "@test begin"
            print_deindent_until(io, source) do ln
                startswith(ln, "end ")
            end
        elseif startswith(ln, "@testset ")
            while true
                popfirst!(source) == "end" && break
            end
        elseif (
            m = match(
                r"""
                ^(?<macroname>@evaltest|@evaltest_throw)\ +
                (?<str>
                    (?:raw)? (?<left>\"\"\"|\") (?<code>.*?) (?<right>\"\"\"|\")
                )\ + begin$
                """x,
                ln,
            )
        ) !== nothing
            ex = Meta.parse(m[:str])
            if ex isa String
                code = ex
            elseif ex.head === :string
                throw(INTERPOLATION_NOT_SUPPORTED_ERROR)
            else
                @assert ex.head == :macrocall
                @assert ex.args[1] == Symbol("@raw_str")
                code = ex.args[end]
            end
            if m[:macroname] == "@evaltest"
                println(io, code)
                while true
                    popfirst!(source) == "end" && break
                end
            elseif m[:macroname] == "@evaltest_throw"
                print(io, THROWING_HEADER)
                println(io, code)
                print(io, THROWING_FOOTER)
                while true
                    popfirst!(source) == "end" && break
                end
            end
        #! format: off
        #=
        elseif (m = match(r"^@throwing *(.*)$", ln)) !== nothing
            print(io, THROWING_HEADER)
            println(io, m[1])
            print(io, THROWING_FOOTER)
        elseif (m = match(r"^@throwing\((.*)\)$", ln)) !== nothing
            print(io, THROWING_HEADER)
            println(io, m[1])
            print(io, THROWING_FOOTER)
        elseif ln == "^@throwing begin"
            print(io, THROWING_HEADER)
            print_deindent_until(io, source) do ln
                startswith(ln, "end ")
            end
            print(io, THROWING_FOOTER)
        =#
        #! format: on
        else
            println(io, ln)
        end
    end
    return String(take!(io))
end

function print_deindent_until(f, io, source)
    indent = typemax(Int)
    while true
        ln = popfirst!(source)
        f(ln) && break
        indent = min(indent, nitems(takewhile(isequal(' '), ln)))
        println(io, remove_global(ln[nextind(ln, indent):end]))
    end
end

function remove_global(ln)
    m = match(r"^global +([^ ]+ = .*)$", ln)
    m === nothing || return m[1]
    return ln
end

"""
    @evaltest "\$code" begin \$tests end
    @evaltest raw"\$code" begin \$tests end

Evaluate `code`, assign it to the variable `ans`, and then run `tests`.

This macro is meant to be processed by `LiterateTest.preprocess`.
"""
macro evaltest(code::AbstractString, tests::Expr)
    ex = :($Test.@testset $code begin
        ans = $Base.include_string(@__MODULE__, $(QuoteNode(code)))
        $tests
    end)
    @assert ex.head == :macrocall
    @assert ex.args[2] isa LineNumberNode
    @assert ex.args[4].head === :block
    @assert ex.args[4].args[1] isa LineNumberNode
    ex.args[2] = __source__
    ex.args[4].args[1] = __source__
    return esc(ex)
end

macro evaltest(str::Expr, tests::Expr)
    code = macroexpand(__module__, str)
    code::AbstractString
    return esc(:($(@__MODULE__).@evaltest $code $tests))
end

struct Success
    value::Any
end

const ∉ᵢₛₐ = !isa

function check_exception(ans)
    Test.@test ans ∉ᵢₛₐ Success
end

"""
    @evaltest_throw "\$code" begin \$tests end
    @evaltest_throw raw"\$code" begin \$tests end

Evaluate `code`, assign the exception thrown to the variable `ans`,
and then run `tests`.

This macro is meant to be processed by `LiterateTest.preprocess`.
"""
macro evaltest_throw(code::AbstractString, tests::Expr)
    code_catch = """
    import LiterateTest
    try
        LiterateTest.Success($code)
    catch err
        err
    end
    """
    ex = :($Test.@testset $code begin
        ans = $Base.include_string(@__MODULE__, $(QuoteNode(code_catch)))
        $check_exception(ans)
        $tests
    end)
    @assert ex.head == :macrocall
    @assert ex.args[2] isa LineNumberNode
    @assert ex.args[4].head === :block
    @assert ex.args[4].args[1] isa LineNumberNode
    ex.args[2] = __source__
    ex.args[4].args[1] = __source__
    return esc(ex)
end

macro evaltest_throw(str::Expr, tests::Expr)
    code = macroexpand(__module__, str)
    code::AbstractString
    return esc(:($(@__MODULE__).@evaltest_throw $code $tests))
end

#=
"""
    @throwing ex

Catch and return the exception thrown in `ex`.
"""
macro throwing(ex)
    quote
        try
            $(esc(ex))
            nothing
        catch err
            err
        end
    end
end
=#

const THROWING_HEADER = """
ans = try # hide
"""

const THROWING_FOOTER = """
catch err; err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, ans) # hide
#-
"""

"""
    LiterateTest.AssertAsTest

A module that exports `Test.@test` as `@assert`.

An intended usage is to import `@assert` before including example file
in test:

```julia
module MyTestExampels
using LiterateTest.AssertAsTest: @assert
include("../examples/file.jl")
end
```

This way, `examples/file.jl` can still use `@assert` for clean
documentation while a better test failure messages are shown when
running the tests.

# Examples
```jldoctest
julia> using LiterateTest.AssertAsTest: @assert

julia> @assert 1 == 1
Test Passed
```
"""
module AssertAsTest
export @assert
using Test: @test
@eval const $(Symbol("@assert")) = $(Symbol("@test"))
end

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end LiterateTest

end