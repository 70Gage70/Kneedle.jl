"""
    viz(x, y, kneedle_result; show_data = true, show_data_smoothed = true, show_knees = true, linewidth = 2.0)

Visualize the computed knees in `kneedle_result` from data `x`, `y`. Optionally show various \
elements based on keyword arguments and set the line width.

This function requires a Makie backend to function, e.g. `import CairoMakie`.

### Example

Install a Makie backend such as `CairoMakie` if you haven't already via the following

```julia-repl
julia> import Pkg
julia> Pkg.add("CairoMakie")
julia> import CairoMakie
```

Once the backend is loaded, we have

```julia-repl
julia> x, y = Testers.CONVEX_INC
julia> kr = kneedle(x, y);
julia> viz(x, y, kr)
```
"""
function viz end

"""
    viz!(ax, x, y, kneedle_result; show_data = true, show_data_smoothed = true, show_knees = true, linewidth = 2.0)

Identical to `viz`, but the plots are added to `ax::Makie.Axis`.

- The plot of `(x, y)` is labeled "Data"
- The plot of `(x_smooth, y_smooth)` is labeled "Smoothed Data"
- The plot of `knees(kneedle_result)` is labeled `Knees`.

This function requires a Makie backend to function, e.g. `import CairoMakie`.

### Example

Install a Makie backend such as `CairoMakie` if you haven't already via the following

```julia-repl
julia> import Pkg
julia> Pkg.add("CairoMakie")
julia> using CairoMakie
```

Once the backend is loaded, we have

```julia-repl
julia> fig = Figure(); ax = Axis(fig[1, 1]);
julia> x, y = Testers.CONVEX_INC
julia> kr = kneedle(x, y);
julia> viz!(ax, x, y, kr)
julia> fig
```
"""
function viz! end