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

