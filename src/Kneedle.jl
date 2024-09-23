module Kneedle

using ArgCheck, Loess
using PrecompileTools: @compile_workload

include("testers.jl")
export Testers

include("main.jl")
export kneedle
    
@compile_workload begin
    x, y = Testers.double_bump()
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
