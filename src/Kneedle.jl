module Kneedle

using ArgCheck, Loess
using PrecompileTools: @compile_workload

include("testers.jl")
export Testers

include("main.jl")
export KneedleResult
export kneedle, knees

include("viz.jl")
export viz
    
@compile_workload begin
    x, y = Testers.double_bump()
    kneedle(x, y, smoothing = 0.1)
    x, y = Testers.CONVEX_INC
    kneedle(x, y, "convex_inc")
    x, y = Testers.CONVEX_DEC
    kneedle(x, y, "convex_dec")
    x, y = Testers.CONCAVE_INC
    kneedle(x, y, "concave_inc")
    x, y = Testers.CONCAVE_DEC
    kneedle(x, y, "concave_dec") 
end

end # module
