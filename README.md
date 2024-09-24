# Kneedle.jl

[![Documentation Status](https://img.shields.io/badge/docs-stable-blue?style=flat-square)](https://70gage70.github.io/Kneedle.jl/docs/kneedle-docs.html)


This is a [Julia](https://julialang.org/) implementation of the Kneedle[^1] knee-finding algorithm. This detects "corners" (or "knees", "elbows", ...) in a dataset `(x, y)`.

# Features

- Exports one main function `kneedle` with the ability to select the shape and number of knees to search for.
- Built-in data smoothing from [Loess.jl](https://github.com/JuliaStats/Loess.jl).
- [Makie](https://docs.makie.org/stable/) extension for quick visualization.

# Installation

This package is in the Julia General Registry. In the Julia REPL, run the following code and follow the prompts:

```julia
import Pkg
Pkg.add("Kneedle")
```

Access the functionality of the package in your code by including the following line:

```julia
using Kneedle
```

# Quick Start

Find a knee automatically using `kneedle(x, y)`:

```julia
using Kneedle
x, y = Testers.CONCAVE_INC
kr = kneedle(x, y) # kr is a `KneedleResult`
knees(kr) # [2], therefore a knee is detected at x = 2
```

In order to use the plotting functionality, a Makie backend is required. For this example, this amounts to including the line `import CairoMakie`. This provides access to the function `viz(x, y, kr; kwargs...)`:

```julia
import CairoMakie
viz(x, y, kr, show_data_smoothed = false) # we didn't use any smoothing here, so no need to show it
```

[!["Plot"](assets/readme.png)](https://70gage70.github.io/Kneedle.jl/)

# Documentation

[Documentation](https://70gage70.github.io/Kneedle.jl/docs/kneedle-docs.html)

# See also

- [kneed](https://github.com/arvkevi/kneed): Knee-finding in Python.

- [Yellowbrick](https://www.scikit-yb.org/en/latest/api/cluster/elbow.html?highlight=knee): Machine learning visualization.

# References

[^1]: Satopaa, Ville, et al. *Finding a "kneedle" in a haystack: Detecting knee points in system behavior.* 2011 31st international conference on distributed computing systems workshops. IEEE, 2011.