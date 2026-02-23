"""
    struct KneedleResult{X}

A container for the output of the Kneedle algorithm.

Use `knees` to access the `knees` field.

Refer to `viz` for visualization.

See the `kneedle` function for further general information.

### Fields 

- `x_smooth`: The smoothed `x` points. Equal to the input `x` points if no smoothing was used.
- `y_smooth`: The smoothed `y` points. Equal to the input `y` points if no smoothing was used.
- `knees`: The a vector of `x` coordinates of the computed knees/elbows.
"""
struct KneedleResult{X<:Real}
    x_smooth::Vector{Float64}
    y_smooth::Vector{Float64}
    knees::Vector{X}
end

"""
    knees(kr::KneedleResult)

Return `kr.knees`.

Refer to `KneedleResult` or `kneedle` for more information.
"""
knees(kr::KneedleResult) = kr.knees

"""
    kneedle(args...)
    
There are several methods for the `kneedle` function as detailed below; each returns a `KneedleResult`. 

Use `knees(kr::KneedleResult)` to obtain the computed knees/elbows as a list of `x` coordinates.

Refer to `viz` for visualization.

Each `kneedle` function contains the args `x` and `y` which refer to the input data. It is required that `x` is sorted.

The two- and three-argument methods accept the kwargs `S` and `smoothing` directly. `S > 0` refers to the sensitivity \
of the knee/elbow detection algorithm in the sense that higher `S` results in fewer detections. `smoothing` refers to \
the amount of smoothing via interpolation that is applied to the data before knee detection. If `smoothing == nothing`, \
it will be bypassed entirely. If `smoothing ∈ [0, 1]`, this parameter is passed directly to \
[Loess.jl](https://github.com/JuliaStats/Loess.jl) via its `span` parameter. Generally, higher `smoothing` results \
in less detection.

The four-argument method instead accepts a `kneedle_scan_algorithm` keyword — see the \
"Kneedle with a specific shape and number of knees" section below.

## Shapes

There are four possible knee/elbow shapes in consideration. If a `kneedle` function takes `shape` as an argument, it \
should be one of these.

- concave increasing: `"|¯"` or `"concave_inc"`
- convex decreasing: `"|_"` or `"convex_dec"`
- concave decreasing: `"¯|"` or `"concave_dec"`
- convex increasing: `"_|"` or `"convex_inc"`

Note that the symbol `¯` is entered by typing `\\highminus<TAB>`

## Methods

### Fully automated kneedle

    kneedle(x, y; S = 1.0, smoothing = nothing, verbose = false)

This function attempts to determine the shape of the knee automatically. Toggle `verbose` to get a printout of \
the guessed shape.

### Kneedle with a specific shape

    kneedle(x, y, shape; S = 1.0, smoothing = nothing)

This function finds knees/elbows with the given `shape`.

### Kneedle with a specific shape and number of knees

    kneedle(x, y, shape, n_knees; kneedle_scan_algorithm = ScanSensitivity())

This function finds exactly `n_knees` knees/elbows with the given `shape`.

The `kneedle_scan_algorithm` keyword accepts a `KneedleScanAlgorithm` subtype. There are five options:

- `ScanSensitivity(; smoothing = nothing)`: Bisect by varying `S` (with a fixed `smoothing`.)
- `ScanSmoothing(; S = 1.0)`: Bisect by varying `smoothing` (with a fixed `S`.)
- `ScanStrength(; S = 1.0, smoothing = nothing)`: Sort knees by strength and take the strongest.
- `ScanJump()`: Find 1 knee by looking for the single biggest jump in `y`. Applies no smoothing.
- `ScanTri(; bboptimize_method = :adaptive_de_rand_1_bin_radiuslimited, niters = 100)`: \
Fit a piecewise linear function to find 1 knee. Requires `import BlackBoxOptim`.

See the docstrings of each `KneedleScanAlgorithm` subtype for details.

## Examples

Find a knee:

```julia-repl
julia> x, y = Testers.CONCAVE_INC
julia> kr1 = kneedle(x, y)
julia> knees(kr1) # [2], meaning that there is a knee at `x = 2`
```

Find a knee with a specific shape:

```julia-repl
julia> kr2 = kneedle(x, y, "concave_inc")
julia> knees(kr1) == knees(kr2) # true
```

Use the pictoral arguments:

```julia-repl
julia> kr3 = kneedle(x, y, "|¯")
julia> knees(kr3) == knees(kr1) # true
```

Find a given number of knees:

```julia-repl
julia> x, y = Testers.double_bump(noise_level = 0.3)
julia> kr4 = kneedle(x, y, "|¯", 2)
julia> length(knees(kr4)) # 2, meaning that the algorithm found 2 knees
```

Find a given number of knees with a different scanning algorithm:

```julia-repl
julia> x, y = Testers.double_bump(noise_level = 0.3)
julia> ksa = ScanSmoothing()
julia> kr5 = kneedle(x, y, "|¯", 2, kneedle_scan_algorithm = ksa)
julia> length(knees(kr5)) # 2, meaning that the algorithm found 2 knees
julia> knees(kr5) == knees(kr4) # false (algorithms are not equivalent in general)
```
"""
function kneedle end


# Compute the main Kneedle algorithm and return a KneedleResult
# Assumes that data is concave increasing, i.e. `|¯` and that `x` is sorted.
function _kneedle(
	x::AbstractVector{<:Real}, 
	y::AbstractVector{<:Real}; 
	S::Real = 1.0, 
	smoothing::Union{Real, Nothing} = nothing)

	n = length(x)
	
	### STEP 1: SMOOTH IF NEEDED
	if smoothing === nothing
		x_s = x
		y_s = y
	else
		model = loess(x, y, span = smoothing)
		x_s = range(extrema(x)..., length = length(x))
		y_s = predict(model, x_s)
	end

	### STEP 2: NORMALIZE
	x_min, x_max = extrema(x_s)
	x_sn = (x_s .- x_min)/(x_max - x_min)
	y_min, y_max = extrema(y_s)
	y_sn = (y_s .- y_min)/(y_max - y_min)

	### STEP 3: DIFFERENCES
	x_d = @view x_sn[:]
	y_d = y_sn - x_sn

	### STEP 4: CANDIDATE LOCAL MAXIMA
	lmx = [i for i in 2:n-1 if (y_d[i - 1] < y_d[i]) && (y_d[i] > y_d[i + 1])]

	knees_res = eltype(x)[]
	
	x_lmx = x_d[lmx]
	y_lmx = y_d[lmx]
	T_lmx = y_lmx .- (S/(n - 1))*sum(x_sn[i + 1] - x_sn[i] for i = 1:n - 1)

	### STEP 5: THRESHOLD
	for i = 1:length(x_lmx)
		for j = lmx[i] + 1:(i == length(x_lmx) ? n : lmx[i + 1] - 1)
			if y_d[j] < T_lmx[i]
				push!(knees_res, x[lmx[i]])
				break
			end
		end
	end
	
    return KneedleResult(collect(float(x_s)), collect(float(y_s)), knees_res)
end

# find knees with a particular shape
function kneedle(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String;
    S::Real = 1.0, 
    smoothing::Union{Real, Nothing} = nothing)

    @argcheck length(x) == length(y) > 0
    @argcheck S > 0
    smoothing !== nothing && @argcheck 0 <= smoothing <= 1
    @argcheck issorted(x)
    @argcheck shape ∈ ["|¯", "|_", "¯|", "_|"] || shape ∈ ["concave_inc", "convex_dec", "concave_dec", "convex_inc"]

    max_x, max_y = maximum(x), maximum(y)

    if shape ∈ ["|¯", "concave_inc"] 
        # default, so no transformation required
        return _kneedle(x, y, S = S, smoothing = smoothing)
    elseif shape ∈ ["|_", "convex_dec"]
        # flip vertically
        kn = _kneedle(x, max_y .- y, S = S, smoothing = smoothing)
        return KneedleResult(kn.x_smooth, max_y .- kn.y_smooth, kn.knees)
    elseif shape ∈ ["¯|", "concave_dec"]
        # flip horizontally; reverse to ensure x increasing
        kn = _kneedle(reverse(max_x .- x), reverse(y), S = S, smoothing = smoothing)
        return KneedleResult(reverse(max_x .- kn.x_smooth), reverse(kn.y_smooth), max_x .- kn.knees)
    elseif shape ∈ ["_|", "convex_inc"]
        # flip horizontally and vertically; reverse to ensure x increasing
        kn = _kneedle(reverse(max_x .- x), reverse(max_y .- y), S = S, smoothing = smoothing)
        return KneedleResult(reverse(max_x .- kn.x_smooth), reverse(max_y .- kn.y_smooth), max_x .- kn.knees)
    end
    
end

# try to guess the shape automatically
function kneedle(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real}; 
    S::Real = 1.0, 
    smoothing::Union{Real, Nothing} = nothing,
    verbose::Bool = false)
    
    _line(X) = y[1] + (y[end] - y[1])*(X - x[1])/(x[end] - x[1])

    concave = sum(y .> _line.(x)) >= length(x)/2
    increasing = _line(x[end]) > _line(x[1])
    
    if concave && increasing 
        verbose && @info "Found concave and increasing |¯"
        return kneedle(x, y, "|¯", S = S, smoothing = smoothing)
    elseif !concave && !increasing
        verbose && @info "Found convex and decreasing |_"
        return kneedle(x, y, "|_", S = S, smoothing = smoothing)
    elseif concave && !increasing
        verbose && @info "Found concave and decreasing ¯|"
        return kneedle(x, y, "¯|", S = S, smoothing = smoothing)
    elseif !concave && increasing
        verbose && @info "Found convex and increasing _|"
        return kneedle(x, y, "_|", S = S, smoothing = smoothing)
    end
end

"""
    abstract type KneedleScanAlgorithm
        
Abstract type for scanning algorithms -- algorithms that attempt to find specific numbers of knees.
"""
abstract type KneedleScanAlgorithm end 

"""
    struct ScanSensitivity
        
Attempt to find a given number of knees by applying bisection on the kneedle `S` ("sensitivity") parameter.

### Constructor

    ScanSensitivity(; smoothing = nothing)

The `smoothing` parameter is held to this constant value during the bisection.
"""
@kwdef struct ScanSensitivity{T<:Union{<:Real, Nothing}} <: KneedleScanAlgorithm
    smoothing::T = nothing
end


function _kneedle_scan(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer,
    kneedle_scan_algorithm::ScanSensitivity)

    smoothing = kneedle_scan_algorithm.smoothing

    # usually, higher S means less knees; define 1/s here since easier to keep track of
    _n_knees(s) = kneedle(x, y, shape, S = 1/s, smoothing = smoothing) |> x -> length(knees(x))
    lb, ub = 0.1, 10.0
    n_iters = 0
    while _n_knees(lb) > n_knees
        lb = lb/2
        n_iters += 1
        if n_iters == 10
            throw(ArgumentError("Could not find the requested number of knees (requested too few)."))
        end
    end

    n_iters = 0
    while _n_knees(ub) < n_knees
        ub = ub*2
        n_iters += 1
        if n_iters == 10
            throw(ArgumentError("Could not find the requested number of knees (requested too many)."))
        end
    end

    a, b = lb, ub
    c = (a + b)/2
    n_iter = 0
    
     # bisection
    while _n_knees(c) != n_knees
        if _n_knees(c) - n_knees > 0
            b = c
        else
            a = c
        end
        
        c = (a + b)/2
        n_iter += 1
    
        if n_iter >= 20
            break
        end
    end

    result = kneedle(x, y, shape, S = 1/c, smoothing = smoothing)
    if length(knees(result)) != n_knees
        throw(ArgumentError("Bisection did not converge to the requested number of knees."))
    end
    return result
end

"""
    struct ScanSmoothing
        
Attempt to find a given number of knees by applying bisection on the kneedle `smoothing` parameter.

### Constructor

    ScanSmoothing(; S = 1.0)

The `S` parameter is held to this constant value during the bisection.
"""
@kwdef struct ScanSmoothing{T<:Real} <: KneedleScanAlgorithm
    S::T = 1.0
end

# use bisection to find a given number of knees by varying the smoothing
function _kneedle_scan(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer, 
    kneedle_scan_algorithm::ScanSmoothing)

    S = kneedle_scan_algorithm.S

    # usually, higher smoothing means less knees; define 1/s here since easier to keep track of
    _n_knees(s) = kneedle(x, y, shape, S = S, smoothing = 1/s) |> x -> length(knees(x))
    ub = 10.0
    n_iters = 0
    while _n_knees(ub) < n_knees
        ub = ub*2
        n_iters += 1
        if n_iters == 10
            throw(ArgumentError("Could not find the requested number of knees (requested too many)."))
        end
    end

    a, b = 1.0, ub
    c = (a + b)/2
    n_iter = 0

    # bisection
    while _n_knees(c) != n_knees
        if _n_knees(c) - n_knees > 0
            b = c
        else
            a = c
        end

        c = (a + b)/2
        n_iter += 1

        if n_iter >= 20
            break
        end
    end

    result = kneedle(x, y, shape, S = S, smoothing = 1/c)
    if length(knees(result)) != n_knees
        throw(ArgumentError("Bisection did not converge to the requested number of knees."))
    end
    return result
end

"""
    struct ScanStrength
        
Sort knees by "strength" (size of the jump to adjacent points) and take the strongest.

### Constructor

    ScanStrength(; S = 1.0, smoothing = nothing)

The `S` and `smoothing` parameters passed to the core kneedle algorithm.
"""
@kwdef struct ScanStrength{T<:Real, R<:Union{<:Real, Nothing}} <: KneedleScanAlgorithm
    S::T = 1.0
    smoothing::R = nothing
end

# sort the knees by "strength" (size of y differences) and take the largest given number
function _kneedle_scan(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer,
    kneedle_scan_algorithm::ScanStrength)

    S = kneedle_scan_algorithm.S
    smoothing = kneedle_scan_algorithm.smoothing

    kr = kneedle(x, y, shape, S = S, smoothing = smoothing)
    ks = knees(kr)

    if length(ks) < n_knees
        throw(ArgumentError("Could not find the requested number of knees (requested too many)."))
    end

    kn_idxs = [findfirst(p -> abs(p - k) < 1e-10, x) for k in ks]

    if shape ∈ ["|¯", "concave_inc", "|_", "convex_dec"] 
        # strongest knee has the biggest jump from the "previous" point
        dy = [abs(y[kn_idx - 1] - y[kn_idx]) for kn_idx in kn_idxs]
    elseif shape ∈ ["¯|", "concave_dec", "_|", "convex_inc"]
        # strongest knee has the biggest jump tp the "next" point
        dy = [abs(y[kn_idx + 1] - y[kn_idx]) for kn_idx in kn_idxs]
    end
    
    sp = sortperm(dy, rev = true) # strongest to weakest
    ks = ks[sp[1:n_knees]]

    return KneedleResult(kr.x_smooth, kr.y_smooth, ks)
end

"""
    struct ScanJump
        
Find 1 knee by looking for the single biggest jump in `y`. Applies no smoothing.

### Constructor

    ScanJump()

Takes no arguments.
"""
struct ScanJump <: KneedleScanAlgorithm end

function _kneedle_scan(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer,
    kneedle_scan_algorithm::ScanJump)

    @argcheck n_knees == 1 "`ScanJump` can only find one knee."

    # for the purposes of "jump", ¯| and |_ have the same behavior in that y looks like BIG BIG BIG SMALL SMALL SMALL
    # the only difference is that the last BIG should be the knee for ¯| and the first SMALL should be the knee for |_
    # similarly, _|  and |¯  look like SMALL SMALL SMALL BIG BIG BIG
    # so the last SMALL should be the knee for _| and the first BIG should be the knee for |¯

    small2big = ["_|", "convex_inc", "|¯", "concave_inc"]

    dy = [y[i + 1] - y[i] for i = 1:length(y)-1]
    sp = sortperm(dy, rev = shape ∈ small2big) |> first

    if shape ∈ ["|_", "convex_dec", "¯|", "concave_dec"]
        sp += 1
    end

    return KneedleResult(collect(float(x)), collect(float(y)), [x[sp]])
end


"""
    struct ScanTri
        
This method regresses `(x, y)` onto a piecewise linear function with three segments to \
find exactly 1 knee of a given shape. To use this method, the package [`BlackBoxOptim`](https://github.com/robertfeldt/BlackBoxOptim.jl) \
must be loaded by running `import BlackBoxOptim`.

### Constructor

    ScanTri(; bboptimize_method::Symbol = :adaptive_de_rand_1_bin_radiuslimited, niters = 100)

- `bboptimize_method`: The optimization algorithm to use. `:adaptive_de_rand_1_bin_radiuslimited` is a strong default; \
consider `:resampling_inheritance_memetic_search` as well, but it is somewhat slower.
- `niters`: The number of iterations in the optimizer.
"""
@kwdef struct ScanTri <: KneedleScanAlgorithm
    bboptimize_method::Symbol = :adaptive_de_rand_1_bin_radiuslimited
    niters::Int = 100
end


# find a given number of knees by searches
function kneedle(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer; 
    kneedle_scan_algorithm::KneedleScanAlgorithm = ScanSensitivity())

    @argcheck n_knees >= 1 
    @argcheck n_knees < length(x)/3 "Too many knees!"
    
    if (kneedle_scan_algorithm isa ScanTri) && isnothing(Base.get_extension(Kneedle, :KneedleBBOExt))
        error("Must load BlackBoxOptim package to use `ScanTri`: import BlackBoxOptim")
    end
    
    return _kneedle_scan(x, y, shape, n_knees, kneedle_scan_algorithm)
end
