using Documenter
using LiterateTest
using Literate

rm(joinpath(@__DIR__, "src", "examples"), force = true, recursive = true)
Literate.markdown(
    joinpath(@__DIR__, "..", "examples", "tests.jl"),
    joinpath(@__DIR__, "src", "examples");
    documenter = true,
)

makedocs(
    sitename = "LiterateTest",
    format = Documenter.HTML(),
    modules = [LiterateTest],
    pages = [
        "Home" => "index.md",
        "Testing LiterateTest.jl" => "examples/tests.md",
    ],
)

deploydocs(; repo = "github.com/tkf/LiterateTest.jl", push_preview = true)
