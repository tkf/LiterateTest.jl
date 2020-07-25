module TestMisc

using Test
using LiterateTest

@testset "@evaltest_throw interpolation" begin
    input = raw"""
    @evaltest_throw "$a" begin
    end
    """
    @test_throws(
        LiterateTest.INTERPOLATION_NOT_SUPPORTED_ERROR,
        LiterateTest.preprocess(input)
    )
end

@testset "@evaltest_throw success" begin
    script = joinpath(@__DIR__, "exec_evaltest_throw_success.jl")
    cmd = `$(Base.julia_cmd()) --startup-file=no $script`
    if VERSION < v"1.1"
        out = Pipe()
        reader = @async begin
            read(out, String)
        end
        proc = run(pipeline(ignorestatus(cmd), stdout = out, stderr = out, stdin = devnull))
        close(out.in)
        output = fetch(reader)
    else
        io = IOBuffer()
        proc = run(pipeline(ignorestatus(cmd), stdout = io, stderr = io, stdin = devnull))
        output = String(take!(io))
    end
    @test proc.exitcode != 0
    @test occursin("Test Failed", output)
end

end  # module
