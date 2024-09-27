module Testers

using ArgCheck
using SpecialFunctions: erf

"""
    const CONVEX_INC

A small set of convex, increasting data `(x, y)` with one knee.
"""
const CONVEX_INC = (0:9, [1, 2, 3, 4, 5, 10, 15, 20, 40, 100])

"""
    const CONVEX_DEC

A small set of convex, decreasing data `(x, y)` with one knee.
"""
const CONVEX_DEC = (0:9, [100, 40, 20, 15, 10, 5, 4, 3, 2, 1])

"""
    const CONCAVE_DEC

A small set of concave, decreasing data `(x, y)` with one knee.
"""
const CONCAVE_DEC = (0:9, [99, 98, 97, 96, 95, 90, 85, 80, 60, 0])

"""
    const CONCAVE_INC

A small set of concave, increasting data `(x, y)` with one knee.
"""
const CONCAVE_INC = (0:9, [0, 60, 80, 85, 90, 95, 96, 97, 98, 99])

"""
    double_bump(; μ1 = -1, μ2 = 5, A1 = 1, A2 = 2, σ1 = 1, σ2 = 1, n_points = 100, noise_level = 0.0)

Return a dataset `(x, y)` with `n_points` points with two knees generated from

`y(x) = A1*Φ(x; μ1, σ1) + A2*Φ(x; μ2, σ2) + noise_level*randn()`

where `Φ(x; μ, σ)` is the CDF of a Normal distribution with mean `μ` and standard deviation `σ`.
"""
function double_bump(;
    μ1::Real = -1, 
    μ2::Real = 5, 
    A1::Real = 1,
    A2::Real = 2,
    σ1::Real = 1, 
    σ2::Real = 1, 
    n_points::Integer = 100,
    noise_level::Real = 0.0)

    @argcheck μ2 > μ1

    _Ncdf(x, μ, σ) = (1/2)*(1 + erf((x - μ)/(sqrt(2)*σ)))

	x = range(μ1 - 3*σ1, μ2 + 3*σ2, length = n_points)
    _y(x) = A1*_Ncdf(x, μ1, σ1) + A2*_Ncdf(x, μ2, σ2) + noise_level*randn()

    return (x, _y.(x))
end

end # module