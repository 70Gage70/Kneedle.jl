module Kneedle

using ArgCheck, Loess
import Random
using PrecompileTools: @compile_workload

include("testers.jl")
export Testers

include("main.jl")
export KneedleResult
export kneedle, knees

include("viz.jl")
export viz
    
@compile_workload begin
    Random.seed!(1234)
    x, y = Testers.double_bump(noise_level = 0.1)
    kneedle(x, y, smoothing = 0.1)
    kneedle(x, y, "|¯", S = 0.1)
    kneedle(x, y, "|¯", 2, scan_type = :S)
    kneedle(x, y, "|¯", 2, scan_type = :smoothing)
end

end # module
