"""
    struct KneedleResult{X, Y}

A container for the output of the Kneedle algorithm.

This object is returned by `kneedle`.

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
"""
knees(kr::KneedleResult) = kr.knees

"""
    kneedle
"""
function kneedle end

"""
	_kneedle(x, y; S = 1.0, smoothing = nothing)

Compute the main Kneedle algorithm and return a [`KneedleResult`](@ref).

Assumes that data is concave increasing, i.e. `|¯` and that `x` is sorted.
"""
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

function _kneedle_scan_S(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer; 
    smoothing::Union{Real, Nothing} = nothing)

    # usually, higher S means less knees; define 1/s here since easier to keep track of
    _n_knees(s) = kneedle(x, y, shape, S = 1/s, smoothing = smoothing) |> x -> length(knees(x))
    lb, ub = 0.1, 10.0
    while _n_knees(lb) > n_knees
        lb = lb/2
    end

    while _n_knees(ub) < n_knees
        ub = ub*2
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

function _kneedle_scan_smooth(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String, 
    n_knees::Integer; 
    S::Real = 1.0)

    # usually, higher smoothing means less knees; define 1/s here since easier to keep track of
    _n_knees(s) = kneedle(x, y, shape, S = S, smoothing = 1/s) |> x -> length(knees(x))
    ub = 10.0

    while _n_knees(ub) < n_knees
        ub = ub*2
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