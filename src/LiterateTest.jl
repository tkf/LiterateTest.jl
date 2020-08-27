module LiterateTest

export @dedent, @evaltest, @evaltest_throw, @testset_error

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
            println(io, "ans = begin # hide")
            print_deindent_until(io, source) do ln
                ln == "end"
            end
            println(io, "end # hide")
        elseif (m = match(r"^( *)@test +begin$", ln)) !== nothing
            spaces = m[1]
            re = Regex("^" * spaces * raw"end\b")
            print_deindent_until(io, source) do ln
                match(re, ln) !== nothing
            end
        elseif (m = match(r"^( *)@test\b", ln)) !== nothing
            # remove `@test ...`
        elseif startswith(ln, "@testset ")
            consume_until_end(source)
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
                consume_until_end(source)
            elseif m[:macroname] == "@evaltest_throw"
                print(io, THROWING_HEADER)
                println(io, code)
                print(io, THROWING_FOOTER)
                consume_until_end(source)
            end
        elseif (m = match(r"^@testset_error +(.*) try", ln)) !== nothing
            println(io, "err = try ", m[1], " begin # hide")
            print_deindent_until(io, source) do ln
                startswith(ln, "catch ")
            end
            print(io, "end ", THROWING_FOOTER)
            consume_until_end(source)
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
        elseif (m = match(r"^( *)@dedent +([^ ].*)$", ln)) !== nothing
            println(io, m[2], " # hide")
            spaces = m[1]
            re = Regex("^" * spaces * raw"(end\b.*)$")
            mend = nothing
            print_deindent_until(io, source) do ln
                mend = match(re, ln)
                mend !== nothing
            end
            println(io, mend[1], " # hide")
        elseif match(r"^ *#! format: (on|off)$", ln) !== nothing
            # Filter out JuliaFormatter directives:
            # https://domluna.github.io/JuliaFormatter.jl/dev/skipping_formatting/
        else
            println(io, ln)
        end
    end
    return String(take!(io))
end

function consume_until_end(source)
    consume_until(source) do ln
        match(r"^end\b$", ln) !== nothing
    end
end

function consume_until(f, source)
    while true
        ln = popfirst!(source)
        f(ln) && return ln
    end
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
    m = match(r"^global +([^ ]+ =(\s.*)?)$", ln)
    m === nothing || return m[1]
    return ln
end

"""
    LiterateTest.preprocess_juliaformatter(code::AbstractString) -> code′::String

Remove `#! format: off` and `#! format: on`.  Note that
[`LiterateTest.preprocess`](@ref) does the same preprocessing.
"""
function preprocess_juliaformatter(original::AbstractString)
    io = IOBuffer()
    for ln in eachline(IOBuffer(original))
        if match(r"^ *#! format: (on|off)$", ln) === nothing
            println(io, ln)
        end
    end
    return String(take!(io))
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

"""
    @testset_error label expr
    @testset_error expr

`expr` must contain a `try`-`catch` block.
"""
macro testset_error(label, expr)
    error_symbol = nothing
    testblock = nothing
    trycatch = replace_first_match(expr) do ex
        if isexpr(ex, :try, 3)
            error_symbol = ex.args[2]
            testblock = ex.args[3]
            return ex.args[1]
        end
    end
    if trycatch === nothing
        error("Expression does not contain `try`-`catch` block:\n", expr)
    end
    return quote
        $Test.@testset $label begin
            $err2 =
                try
                    $(something(trycatch))
                    nothing
                catch $err1
                    Some($err1)
                end
            $error_symbol = something($err2)
            $testblock
        end
    end |> esc
end

macro testset_error(expr)
    quote
        $(@__MODULE__).@testset_error "Test set" $expr
    end
end

function replace_first_match(f, ex)
    y = f(ex)
    y === nothing || return y
    ex isa Expr || return nothing
    for (i, a) in pairs(ex.args)
        y = replace_first_match(f, a)
        y === nothing && continue
        return Some(Expr(ex.head, ex.args[1:i-1]..., something(y), ex.args[i+1:end]...))
    end
    return nothing
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
err = try # hide
"""

const THROWING_FOOTER = """
catch _err; _err; end # hide
print(stdout, "ERROR: ") # hide
showerror(stdout, err) # hide
#-
"""

"""
    @dedent begin
        ex
    end

A no-op macro that just evaluates `ex`.

This macro is meant to be processed by `LiterateTest.preprocess`.
"""
macro dedent(ex)
    esc(ex)
end

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
