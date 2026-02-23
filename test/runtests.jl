using Kneedle
using Test
import Random
Random.seed!(1234)

@testset "CONCAVE_DEC" begin
    x, y = Testers.CONCAVE_DEC
    @test knees(kneedle(x, y)) == [7]
    @test knees(kneedle(x, y, "concave_dec")) == [7]
    @test knees(kneedle(x, y, "concave_dec", 1)) == [7]
end

@testset "CONCAVE_INC" begin
    x, y = Testers.CONCAVE_INC
    @test knees(kneedle(x, y)) == [2]
    @test knees(kneedle(x, y, "concave_inc")) == [2]
    @test knees(kneedle(x, y, "concave_inc", 1)) == [2]
end

@testset "CONVEX_INC" begin
    x, y = Testers.CONVEX_INC
    @test knees(kneedle(x, y)) == [7]
    @test knees(kneedle(x, y, "convex_inc")) == [7]
    @test knees(kneedle(x, y, "convex_inc", 1)) == [7]
end

@testset "CONVEX_DEC" begin
    x, y = Testers.CONVEX_DEC
    @test knees(kneedle(x, y)) == [2]
    @test knees(kneedle(x, y, "convex_dec")) == [2]
    @test knees(kneedle(x, y, "convex_dec", 1)) == [2]
end

@testset "Pictoral shape notation equivalence" begin
    datasets = [
        (Testers.CONCAVE_INC, "|¯", "concave_inc"),
        (Testers.CONVEX_DEC,  "|_", "convex_dec"),
        (Testers.CONCAVE_DEC, "¯|", "concave_dec"),
        (Testers.CONVEX_INC,  "_|", "convex_inc"),
    ]
    for ((x, y), pic, text) in datasets
        @test knees(kneedle(x, y, pic)) == knees(kneedle(x, y, text))
    end
end

@testset "KneedleResult structure" begin
    x, y = Testers.CONCAVE_INC
    kr = kneedle(x, y, "concave_inc")
    @test kr.knees == knees(kr)
    @test kr.x_smooth isa Vector{Float64}
    @test kr.y_smooth isa Vector{Float64}
    @test length(kr.x_smooth) == length(x)
    @test length(kr.y_smooth) == length(y)
end

@testset "Smoothing parameter" begin
    Random.seed!(42)
    x, y = Testers.double_bump(noise_level=0.1)
    kr_smooth = kneedle(x, y, "|¯", smoothing=0.5)
    kr_none = kneedle(x, y, "|¯")
    @test kr_smooth isa KneedleResult
    @test kr_smooth.y_smooth != kr_none.y_smooth

    # smoothing on simple data still finds knee
    x2, y2 = Testers.CONCAVE_INC
    kr2 = kneedle(x2, y2, "concave_inc", smoothing=0.9)
    @test length(knees(kr2)) >= 1
end

@testset "Sensitivity parameter (S)" begin
    Random.seed!(42)
    x, y = Testers.double_bump(noise_level=0.3)
    kr_low = kneedle(x, y, "|¯", S=0.5)
    kr_high = kneedle(x, y, "|¯", S=5.0)
    @test length(knees(kr_high)) <= length(knees(kr_low))

    # default S works
    kr_default = kneedle(x, y, "|¯", S=1.0)
    @test kr_default isa KneedleResult
end

@testset "ScanSensitivity" begin
    Random.seed!(42)
    x, y = Testers.double_bump(noise_level=0.1)
    kr = kneedle(x, y, "|¯", 2, kneedle_scan_algorithm=ScanSensitivity())
    @test length(knees(kr)) == 2

    # with smoothing kwarg
    kr2 = kneedle(x, y, "|¯", 2, kneedle_scan_algorithm=ScanSensitivity(smoothing=0.5))
    @test length(knees(kr2)) == 2
end

@testset "ScanSmoothing" begin
    Random.seed!(42)
    x, y = Testers.double_bump(noise_level=0.1)
    kr = kneedle(x, y, "|¯", 2, kneedle_scan_algorithm=ScanSmoothing())
    @test length(knees(kr)) == 2

    # with S kwarg
    kr2 = kneedle(x, y, "|¯", 2, kneedle_scan_algorithm=ScanSmoothing(S=0.5))
    @test length(knees(kr2)) == 2
end

@testset "ScanStrength" begin
    Random.seed!(42)
    x, y = Testers.double_bump(noise_level=0.1)
    kr = kneedle(x, y, "|¯", 2, kneedle_scan_algorithm=ScanStrength())
    @test length(knees(kr)) == 2

    # requesting more knees than available throws (simple data has only 1 knee)
    x2, y2 = Testers.CONCAVE_INC
    @test_throws ArgumentError kneedle(x2, y2, "|¯", 3, kneedle_scan_algorithm=ScanStrength())
end

@testset "ScanJump" begin
    datasets = [
        (Testers.CONCAVE_INC, "|¯"),
        (Testers.CONVEX_DEC,  "|_"),
        (Testers.CONCAVE_DEC, "¯|"),
        (Testers.CONVEX_INC,  "_|"),
    ]
    for ((x, y), shape) in datasets
        kr = kneedle(x, y, shape, 1, kneedle_scan_algorithm=ScanJump())
        @test length(knees(kr)) == 1
    end

    # errors if n_knees != 1
    x, y = Testers.CONCAVE_INC
    @test_throws ArgumentError kneedle(x, y, "|¯", 2, kneedle_scan_algorithm=ScanJump())
end

@testset "double_bump generator" begin
    Random.seed!(99)
    x, y = Testers.double_bump(noise_level=0.0)
    @test length(x) == 100
    @test length(y) == 100
    @test issorted(x)

    # deterministic with no noise
    Random.seed!(99)
    x2, y2 = Testers.double_bump(noise_level=0.0)
    @test x == x2
    @test y == y2

    # custom length
    x3, y3 = Testers.double_bump(n_points=50, noise_level=0.0)
    @test length(x3) == 50

    # errors when μ2 <= μ1
    @test_throws ArgumentError Testers.double_bump(μ1=5, μ2=3)
    @test_throws ArgumentError Testers.double_bump(μ1=5, μ2=5)
end

@testset "Input validation" begin
    x, y = Testers.CONCAVE_INC

    # mismatched lengths
    @test_throws ArgumentError kneedle([1, 2, 3], [1, 2], "|¯")

    # unsorted x
    @test_throws ArgumentError kneedle([3, 1, 2], [1, 2, 3], "|¯")

    # S <= 0
    @test_throws ArgumentError kneedle(x, y, "|¯", S=0)
    @test_throws ArgumentError kneedle(x, y, "|¯", S=-1)

    # invalid shape
    @test_throws ArgumentError kneedle(x, y, "invalid_shape")

    # smoothing out of [0,1]
    @test_throws ArgumentError kneedle(x, y, "|¯", smoothing=-0.1)
    @test_throws ArgumentError kneedle(x, y, "|¯", smoothing=1.5)

    # n_knees < 1
    @test_throws ArgumentError kneedle(x, y, "|¯", 0)

    # too many knees
    @test_throws ArgumentError kneedle(x, y, "|¯", 5)
end
