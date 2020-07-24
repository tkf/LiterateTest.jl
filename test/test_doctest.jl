module TestDoctest

using Documenter
using Test
using LiterateTest

@testset "/docs" begin
    doctest(LiterateTest; manual = true)
end

@testset "/test/doctests" begin
    doctest(joinpath((@__DIR__), "doctests"), Module[])
end

end  # module
