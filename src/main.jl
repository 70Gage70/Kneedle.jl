"""
    struct KneedleResult{X}

A container for the output of the Kneedle algorithm.

Use [`knees`](@ref) to access the `knees` field.

Refer to [`viz`](@ref) for visualization.

See the [`kneedle`](@ref) function for further general information.

### Fields 

- `x_smooth`: The smoothed `x` points.
- `y_smooth`: The smoothed `y` points.
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

Refer to [`KneedleResult`](@ref) or [`kneedle`](@ref) for more information.
"""
knees(kr::KneedleResult) = kr.knees

"""
    kneedle(args...,)
    
There are several methods for the `kneedle` function as detailed below; each returns a [`KneedleResult`](@ref). 

Use `knees(kr::KneedleResult)` to obtain the computed knees/elbows as a list of `x` coordinates.

Refer to [`viz`](@ref) for visualization.

Each `kneedle` function contains the args `x` and `y` which refer to the input data. It is required that `x` is sorted.

Each `kneedle` function contains the kwargs `S` and `smoothing`. `S > 0` refers to the sensitivity of the knee/elbow \
detection algorithm in the sense that higher `S` results in fewer detections. `smoothing` refers to the amount of \
smoothing via interpolation that is applied to the data before knee detection. If `smoothing == nothing`, it will \
be bypassed entirely. If `smoothing ∈ [0, 1]`, this parameter is passed directly to \
[Loess.jl](https://github.com/JuliaStats/Loess.jl) via its `span` parameter. Generally, higher `smoothing` results \
in less detection.

## Shapes

There are four possible knee/elbow shapes in consideration. If a `kneedle` function takes `shape` as an argument, it \
should be one of these.

- concave increasing: `|¯` or `"concave_inc"`
- convex decreasing: `|_` or `"convex_dec"`
- concave decreasing: `¯|` or `"concave_dec"`
- convex increasing: `_|` or `"convex_inc"`

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

    kneedle(x, y, shape, n_knees; scan_type = :S, S = 1.0, smoothing = nothing)

This function finds exactly `n_knees` knees/elbows with the given `shape`.

This works by bisecting either `S` (if `scan_type == :S`) or `smoothing` (if `scan_type == :smoothing`).

## Examples

Find a knee:

```julia-repl
julia> x, y = Testers.CONCAVE_INC
julia> kr1 = kneedle(x, y)
julia> knees(kr1) # 2, meaning that there is a knee at `x = 2`
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
"""
function kneedle end


# C ompute the main Kneedle algorithm and return a [`KneedleResult`](@ref).
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
	x_d = deepcopy(x_sn)
	y_d = y_sn - x_sn

	### STEP 4: CANDIDATE LOCAL MAXIMA
	lmx = [i for i in 2:n-1 if (y_d[i - 1] < y_d[i]) && (y_d[i] > y_d[i + 1])]
	
	if length(lmx) == 1
        return KneedleResult(collect(float(x_s)), collect(float(y_s)), [x[lmx[1]]])
	end

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

# use bisection to find a given number of knees by varying the sensitivity
function _kneedle_scan_S(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer; 
    smoothing::Union{Real, Nothing} = nothing)

    # usually, higher S means less knees; define 1/s here since easier to keep track of
    _n_knees(s) = kneedle(x, y, shape, S = 1/s, smoothing = smoothing) |> x -> length(knees(x))
    lb, ub = 0.1, 10.0
    n_iters = 0
    while _n_knees(lb) > n_knees
        lb = lb/2
        n_iters += 1
        if n_iters == 10
            error("Could not find the requested number of knees (requested too few).")
        end
    end

    n_iters = 0
    while _n_knees(ub) < n_knees
        ub = ub*2
        n_iters += 1
        if n_iters == 10
            error("Could not find the requested number of knees (requested too many.)")
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

    return kneedle(x, y, shape, S = 1/c, smoothing = smoothing)
end

# use bisection to find a given number of knees by varying the smoothing
function _kneedle_scan_smooth(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer; 
    S::Real = 1.0)

    # usually, higher smoothing means less knees; define 1/s here since easier to keep track of
    _n_knees(s) = kneedle(x, y, shape, S = S, smoothing = 1/s) |> x -> length(knees(x))
    ub = 10.0
    n_iters = 0
    while _n_knees(ub) < n_knees
        ub = ub*2
        n_iters += 1
        if n_iters == 10
            error("Could not find the requested number of knees (requested too many).")
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

    return kneedle(x, y, shape, S = S, smoothing = 1/c)
end

# find a given number of knees by searching either the sensitivity or the smoothing
function kneedle(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer; 
    scan_type::Symbol = :S,
    S::Real = 1.0,
    smoothing::Union{Real, Nothing} = nothing)

    @argcheck n_knees >= 1 
    @argcheck n_knees < length(x)/3 "Too many knees!"
    @argcheck scan_type ∈ [:S, :smoothing]

    if scan_type == :S
        return _kneedle_scan_S(x, y, shape, n_knees, smoothing = smoothing)
    elseif scan_type == :smoothing
        return _kneedle_scan_smooth(x, y, shape, n_knees, S = S)
    end
end