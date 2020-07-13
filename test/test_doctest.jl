module TestDoctest

using Documenter
using Test
using LiterateTest

@testset "/docs" begin
    doctest(LiterateTest; manual = true)
end

end  # module
