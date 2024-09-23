# struct KneedleResult{X<:AbstractVector, Y<:AbstractVector}
#     x::X
#     y::Y
#     y_smoothed::Vector{Float64}
#     knees::X
# end

"""
	_kneedle(x, y; S = 1.0, smoothing = nothing)

Assumes that data is concave increasing, i.e. `|¯`.
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
		return [x[lmx[1]]]
	end

	knees = Float64[]
	
	x_lmx = x_d[lmx]
	y_lmx = y_d[lmx]
	T_lmx = y_lmx .- (S/(n - 1))*sum(x_sn[i + 1] - x_sn[i] for i = 1:n - 1)
	
	### STEP 5: THRESHOLD
	for i = 1:length(x_lmx)
		for j = lmx[i] + 1:(i == length(x_lmx) ? n : lmx[i + 1] - 1)
			if y_d[j] < T_lmx[i]
				push!(knees, x[lmx[i]])
				break
			end
		end
	end
	
	return knees
end

"""
    kneedle(x, y, shape; S = 1.0, smoothing = nothing)
"""
function kneedle(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real},
    shape::String;
    S::Real = 1.0, 
    smoothing::Union{Real, Nothing} = nothing)

    @argcheck length(x) == length(y) > 0
    @argcheck S > 0
    smoothing !== nothing && @argcheck 0 <= smoothing <= 1
    @argcheck issorted(x) || issorted(-x)
    @argcheck shape ∈ ["|¯", "|_", "¯|", "_|"] || shape ∈ ["concave_inc", "convex_dec", "concave_dec", "convex_inc"]

    if shape ∈ ["|¯", "concave_inc"] 
        return _kneedle(x, y, S = S, smoothing = smoothing)
    elseif shape ∈ ["|_", "convex_dec"]
        return _kneedle(x, maximum(y) .- y, S = S, smoothing = smoothing)
    elseif shape ∈ ["¯|", "concave_dec"]
        max_x = maximum(x)
        kn = _kneedle(max_x .- x, y, S = S, smoothing = smoothing)
        return max_x .- kn
    elseif shape ∈ ["_|", "convex_inc"]
        max_x = maximum(x)
        kn = _kneedle(max_x .- x, maximum(y) .- y, S = S, smoothing = smoothing)
        return max_x .- kn
    end
    
end

function kneedle(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real}; 
    S::Real = 1.0, 
    smoothing::Union{Real, Nothing} = nothing)
    
    _line(X) = y[1] + (y[end] - y[1])*(X - x[1])/(x[end] - x[1])

    concave = sum(y .> _line.(x)) >= length(x)/2
    increasing = _line(x[end]) > _line(x[1])
    
    if concave && increasing 
        return kneedle(x, y, "|¯", S = S, smoothing = smoothing)
    elseif !concave && !increasing
        return kneedle(x, y, "|_", S = S, smoothing = smoothing)
    elseif concave && !increasing
        return kneedle(x, y, "¯|", S = S, smoothing = smoothing)
    elseif !concave && increasing
        return kneedle(x, y, "_|", S = S, smoothing = smoothing)
    end
end