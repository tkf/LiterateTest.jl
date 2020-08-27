var documenterSearchIndex = {"docs":
[{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"EditURL = \"https://github.com/tkf/LiterateTest.jl/blob/master/examples/tests.jl\"","category":"page"},{"location":"examples/tests/#tests","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"","category":"section"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"using Test\nusing LiterateTest","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"This file tests LiterateTest.jl using plain Literate.jl-compatible source code.","category":"page"},{"location":"examples/tests/#Helper-function","page":"Testing LiterateTest.jl","title":"Helper function","text":"","category":"section"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"decode_output(output) = join((strip(ln, '|') for ln in split(output, \"\\n\")), \"\\n\")\n\n@assert decode_output(\"\"\"\n    |a|\n    |b|\n    \"\"\") === \"\"\"\n    a\n    b\n    \"\"\"","category":"page"},{"location":"examples/tests/#Removing-ans-begin-and-end","page":"Testing LiterateTest.jl","title":"Removing ans = begin and end","text":"","category":"section"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    ans = begin\n        1 + 2\n    end\n    \"\"\"\n\noutput = decode_output(\"\"\"\n    |ans = begin # hide|\n    |1 + 2|\n    |end # hide|\n    \"\"\")\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/#Removing-@testset","page":"Testing LiterateTest.jl","title":"Removing @testset","text":"","category":"section"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    @testset begin\n        @test 1 + 2 == 3\n    end\n    \"\"\"\n\noutput = \"\"\"\n    \"\"\"\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"Above two patterns can be combined to write tests like this that are not visible in the Documenter.jl output:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"ans = begin\n    1 + 2  # only this line is visible in the documentation\nend\n@testset begin\n    @test ans == 3\nend\nnothing  # hide","category":"page"},{"location":"examples/tests/#Removing-@test-begin-and-end-...","page":"Testing LiterateTest.jl","title":"Removing @test begin and end ...","text":"","category":"section"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    @test begin\n        1 + 2\n    end == 3\n    \"\"\"\n\noutput = \"\"\"\n    1 + 2\n    \"\"\"\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"When extracting the result of @test, it's useful to use global. However, global is not needed when @test begin ... end is removed.  Thus, global is removed from the code as well:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    @test begin\n        global y = 1 + 2\n    end == 3\n    y + 3\n    \"\"\"\n\noutput = \"\"\"\n    y = 1 + 2\n    y + 3\n    \"\"\"\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"@test itself can be indented","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    if VERSION >= v\"1.4\"\n        @test begin\n            code\n        end == 1\n    end\n    \"\"\"\n\noutput = \"\"\"\n    if VERSION >= v\"1.4\"\n    code\n    end\n    \"\"\"\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/#Extracting-code-from-@evaltest-\"code\"","page":"Testing LiterateTest.jl","title":"Extracting $code from @evaltest \"$code\"","text":"","category":"section"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    @evaltest \"1 + 2\" begin\n        @test ans == 3\n        @test ans isa Int\n    end\n    \"\"\"\n\noutput = \"\"\"\n    1 + 2\n    \"\"\"\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"Note that \"$code\" will be used as the @testset title when it's evaluated withtout the transformation.","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"@evaltest \"1 + 2\" begin\n    @test ans == 3\n    @test ans isa Int\nend\nnothing  # hide","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"note: Note\n@evaltest \"1 + 2\" begin ... above is shown in this Documenter.jl output because this file is not processed by LiterateTest.preprocess.","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"When using $ in the code, raw\"\" can be useful:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = raw\"\"\"\n    x = 1\n    @evaltest raw\":(1 + $x)\" begin\n        @test ans == :(1 + $x)\n    end\n    \"\"\"\n\noutput = raw\"\"\"\n    x = 1\n    :(1 + $x)\n    \"\"\"\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"Demo:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"x = 1\n@evaltest raw\":(1 + $x)\" begin\n    @test ans == :(1 + $x)\nend\nnothing  # hide","category":"page"},{"location":"examples/tests/#Showing-error-thrown-from-code-in-@evaltest_throw-\"code\"","page":"Testing LiterateTest.jl","title":"Showing error thrown from $code in @evaltest_throw \"$code\"","text":"","category":"section"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    @evaltest_throw \\\"\\\"\\\"error(\"msg\")\\\"\\\"\\\" begin\n        @test ans == ErrorException(1)\n    end\n    \"\"\"\n\nText(LiterateTest.preprocess(input))","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"It's a bit tricky to test this in Literate.jl:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"output = decode_output(\"\"\"\n    |ans = try # hide|\n    |error(\"msg\")|\n    |catch err; err; end # hide|\n    |print(stdout, \"ERROR: \") # hide|\n    |showerror(stdout, ans) # hide|\n    |#-|\n    \"\"\")\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"Demo:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"@evaltest_throw \"\"\"error(\"msg\")\"\"\" begin\n    @test ans == ErrorException(\"msg\")\nend\nnothing  # hide","category":"page"},{"location":"examples/tests/#De-indenting-code-in-@dedent-begin-code-end","page":"Testing LiterateTest.jl","title":"De-indenting code in @dedent begin code end","text":"","category":"section"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    @dedent @time begin\n        code\n    end\n    \"\"\"\n\noutput = decode_output(\"\"\"\n    |@time begin # hide|\n    |code|\n    |end # hide|\n    \"\"\")\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"Demo:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"@dedent @time begin\n    1 + 1\nend","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"Expressions after end are ignored","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    @dedent @assert begin\n        code\n    end == 1\n    \"\"\"\n\noutput = decode_output(\"\"\"\n    |@assert begin # hide|\n    |code|\n    |end == 1 # hide|\n    \"\"\")\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"Demo:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"@dedent @assert begin\n    1 + 1\nend == 2","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"@dedent works with assignments","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    @dedent y1 = begin\n        1 + 1\n    end\n    @dedent y2 = begin\n        3 - 1\n    end\n    @test y1 == y2\n    \"\"\"\n\noutput = decode_output(\"\"\"\n    |y1 = begin # hide|\n    |1 + 1|\n    |end # hide|\n    |y2 = begin # hide|\n    |3 - 1|\n    |end # hide|\n    \"\"\")\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"Demo:","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"@dedent y1 = begin\n    1 + 1\nend\n@dedent y2 = begin\n    3 - 1\nend\n@test y1 == y2\nnothing  # hide","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"@dedent itself can be indented","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"input = \"\"\"\n    if VERSION >= v\"1.4\"\n        @dedent @assert begin\n            code\n        end == 1\n    end\n    \"\"\"\n\noutput = decode_output(\"\"\"\n    |if VERSION >= v\"1.4\"|\n    |@assert begin # hide|\n    |code|\n    |end == 1 # hide|\n    |end|\n    \"\"\")\n\n@assert LiterateTest.preprocess(input) == output","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"","category":"page"},{"location":"examples/tests/","page":"Testing LiterateTest.jl","title":"Testing LiterateTest.jl","text":"This page was generated using Literate.jl.","category":"page"},{"location":"#LiterateTest.jl","page":"Home","title":"LiterateTest.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"LiterateTest\nLiterateTest.config\nLiterateTest.preprocess\nLiterateTest.@evaltest\nLiterateTest.@evaltest_throw\nLiterateTest.@dedent\nLiterateTest.AssertAsTest","category":"page"},{"location":"#LiterateTest","page":"Home","title":"LiterateTest","text":"LiterateTest\n\n(Image: Dev) (Image: GitHub Actions)\n\nSmall utilities for writing testable documentation using Literate.jl.\n\n\n\n\n\n","category":"module"},{"location":"#LiterateTest.config","page":"Home","title":"LiterateTest.config","text":"LiterateTest.config(; overloads...) -> config::Dict{Symbol,Ans}\n\nConstruct a config dictionary that can be passed to Literate.markdown etc.\n\nLiterateTest.config post-composes given preprocess function (default: identity) with LiterateTest.preprocess.\n\n\n\n\n\n","category":"function"},{"location":"#LiterateTest.preprocess","page":"Home","title":"LiterateTest.preprocess","text":"LiterateTest.preprocess(code::AbstractString) -> code′::String\n\nRemove testing related code from code.\n\nSee Testing LiterateTest.jl for examples of how it works.\n\nnote: Note\nCurrently, LiterateTest.preprocess is implemented as a plain line-based transformation.  It may break with complex expressions.\n\nLiterateTest.preprocess does the following transformations:\n\nRemove ans = begin and end from\nans = begin\n    # any number of lines with consistent indentation\nend\nand then de-indent the lines inside begin ... end.\nRemove @test begin and end ... from\n@test begin\n    # any number of lines with consistent indentation\nend # any content after `end` is ignored.\nand then de-indent the lines inside begin ... end.  Also remove global from assignments of the form global ... = ... if appears at the shallowest indentation level.\nRemove the @testset block of the form\n@testset ...\n    ...\nend\nExtract $code from\n@evaltest \"$code\" ...\n    ...\nend\nand remove everything else.\n\n\n\n\n\n","category":"function"},{"location":"#LiterateTest.@evaltest","page":"Home","title":"LiterateTest.@evaltest","text":"@evaltest \"$code\" begin $tests end\n@evaltest raw\"$code\" begin $tests end\n\nEvaluate code, assign it to the variable ans, and then run tests.\n\nThis macro is meant to be processed by LiterateTest.preprocess.\n\n\n\n\n\n","category":"macro"},{"location":"#LiterateTest.@evaltest_throw","page":"Home","title":"LiterateTest.@evaltest_throw","text":"@evaltest_throw \"$code\" begin $tests end\n@evaltest_throw raw\"$code\" begin $tests end\n\nEvaluate code, assign the exception thrown to the variable ans, and then run tests.\n\nThis macro is meant to be processed by LiterateTest.preprocess.\n\n\n\n\n\n","category":"macro"},{"location":"#LiterateTest.@dedent","page":"Home","title":"LiterateTest.@dedent","text":"@dedent begin\n    ex\nend\n\nA no-op macro that just evaluates ex.\n\nThis macro is meant to be processed by LiterateTest.preprocess.\n\n\n\n\n\n","category":"macro"},{"location":"#LiterateTest.AssertAsTest","page":"Home","title":"LiterateTest.AssertAsTest","text":"LiterateTest.AssertAsTest\n\nA module that exports Test.@test as @assert.\n\nAn intended usage is to import @assert before including example file in test:\n\nmodule MyTestExampels\nusing LiterateTest.AssertAsTest: @assert\ninclude(\"../examples/file.jl\")\nend\n\nThis way, examples/file.jl can still use @assert for clean documentation while a better test failure messages are shown when running the tests.\n\nExamples\n\njulia> using LiterateTest.AssertAsTest: @assert\n\njulia> @assert 1 == 1\nTest Passed\n\n\n\n\n\n","category":"module"}]
}