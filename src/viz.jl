"""
    viz(x, y, kneedle_result; show_data = true, show_data_smoothed = true, show_knees = true, linewidth = 2.0)

Visualize the computed knees in `kneedle_result` from data `x`, `y`. Optonally show various \
elements based on keyword arguments and set the line width.

This function requires a Makie backend to function, e.g. `import CairoMakie`.

### Example

```julia-repl
julia> x, y = Testers.CONVEX_INC; kr = kneedle(x, y);
julia> viz(x, y, kr)
```
"""
function viz end