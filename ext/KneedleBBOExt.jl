module KneedleBBOExt

using ArgCheck
using Kneedle
using BlackBoxOptim
using PrecompileTools: @compile_workload
import Random

# """
# 	_y_tri(x; params)

# A piecewise linear function with three segments.
#     - `y_1 = m_1 x + b_1` for `0 <= x < k1`
#     - `y_2 = m_2 x + b_2` for `k1 <= x <= k2`
#     - `y_3 = m_3 x + b_3` for `k2 < x <= 1`

# `params` is an 8-vector: `(m1, b1, m2, b2, m3, b3, k1, k2)`. 
# """
function _y_tri(x::Real; params::AbstractVector{<:Real})
	m1, b1, m2, b2, m3, b3, k1, k2 = params
	if 0 <= x < k1
		return m1*x + b1
	elseif k1 <= x <= k2
		return m2*x + b2
	elseif k2 < x <= 1
		return m3*x + b3
	else
		error("x outside [0, 1]")
	end
end 

# """
# 	_get_k1k2(x, y; bboptimize_Method)

# Regress the `(x, y)` data onto `_y_tri` and return `(bf, yhat)`.
# """
function _get_k1k2(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real}; 
    bboptimize_Method::Symbol)

	x_min = minimum(x)
	x_scaled = x .- x_min
	x_max = maximum(x_scaled)
	x_scaled = x_scaled/x_max

	y_min = minimum(y)
	y_scaled = y .- y_min
	y_max = maximum(y_scaled)
	y_scaled = y_scaled/y_max

	loss_reg(params) = y_scaled - _y_tri.(x_scaled; params) |> L -> sum(sqrt.(L .^ 2))
	loss_k1k2(params) = params[end-1] < params[end] ? 0.0 : 100.0
	loss(params) = loss_reg(params) + loss_k1k2(params)

	res = bboptimize(loss; 
			SearchRange = [
				(-10.0, 10.0), # m1
				(-10.0, 10.0), # b1
				(-10.0, 10.0), # m2
				(-10.0, 10.0), # b2
				(-10.0, 10.0), # m3
				(-10.0, 10.0), # b3
				(0.0, 1.0), # k1
				(0.0, 1.0), # k2
			],
			Method = bboptimize_Method,
			TraceMode = :silent
	)
	
	bf = best_fitness(res)
	bc = best_candidate(res)
	k1_scaled, k2_scaled = bc[end-1], bc[end]

	k1 = x_max*k1_scaled + x_min
	k2 = x_max*k2_scaled + x_min

	yhat = y_max * _y_tri.(x_scaled; params=bc) .+ y_min

	return (bf, yhat)
end

# LOOP OVER THIS 10 TIMES AND TAKE BEST\

# find a knee by regressing the data onto a piecewise linear function
function Kneedle._kneedle_scan_opt(
    x::AbstractVector{<:Real}, 
    y::AbstractVector{<:Real}, 
    shape::String, 
    n_knees::Integer; 
    bboptimize_Method::Symbol = :adaptive_de_rand_1_bin_radiuslimited,
	niters::Integer = 100)

	# also try :resampling_inheritance_memetic_search, but quite slow
	
    @argcheck length(x) == length(y) > 0
    @argcheck issorted(x)
    @argcheck shape ∈ ["|¯", "|_", "¯|", "_|"] || shape ∈ ["concave_inc", "convex_dec", "concave_dec", "convex_inc"]
	@argcheck n_knees == 1 "The `:tri` scan can only find one knee."

	bf = Inf
	yhat = nothing
	for _ = 1:niters
		_bf, _yhat = _get_k1k2(x, y; bboptimize_Method = bboptimize_Method)
		if _bf < bf
			yhat = _yhat
		end
	end 

	return Kneedle.kneedle(Float64.(collect(x)), Float64.(collect(yhat)), shape, n_knees, scan_type=:S)
end 

@compile_workload begin
    Random.seed!(1234)
    x, y = Testers.CONVEX_INC
    Kneedle._kneedle_scan_opt(x, y, "convex_inc", 1)
end

end # module