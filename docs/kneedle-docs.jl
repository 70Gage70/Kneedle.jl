### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 120250f8-5689-443d-bf99-dca7e1b41a82
begin
	import Pkg
	Pkg.add(url="https://github.com/70Gage70/Kneedle.jl", rev="master")
	Pkg.add([
		"CairoMakie", 
		"PlutoUI"])
	using PlutoUI
	import Random
end

# ╔═╡ a70f7664-47b1-43c2-93aa-4a8e3886e38f
using Kneedle

# ╔═╡ efaedc36-961b-4476-9a72-cca18ac7f385
using CairoMakie

# ╔═╡ 1d5ffaa0-224b-4587-b7ae-859a26512cc3
md"""
# Kneedle.jl
"""

# ╔═╡ 14bbc45a-621e-4b88-a821-0ba87083adc2
md"""
# Introduction
"""

# ╔═╡ 3f40fc7d-4bb4-4763-b03c-f32d23ee3b48
md"""
This is the documentation for the package [Kneedle.jl](https://github.com/70Gage70/Kneedle.jl). The documentation is powered by a [Pluto.jl](https://plutojl.org/) notebook. Note that executed code shows the result *above* the code!

Kneedle.jl is a [Julia](https://julialang.org/) implementation of the Kneedle[^1] knee-finding algorithm. This detects "corners" (or "knees", "elbows", ...) in a dataset `(x, y)`.
"""

# ╔═╡ 3638014c-ed4f-4c50-a91c-edf3db6fc97d
md"""
# Features
"""

# ╔═╡ 9b5823a0-2f97-464a-929a-0596dc6a99a2
md"""
- Exports one main function `kneedle` with the ability to select the shape and number of knees to search for.
- Built-in data smoothing from [Loess.jl](https://github.com/JuliaStats/Loess.jl).
- [Makie](https://docs.makie.org/stable/) extension for quick visualization.
"""

# ╔═╡ 74fc8395-26cf-4595-ac96-abecf7273d6c
md"""
# Installation
"""

# ╔═╡ ec2763fd-6d65-4d61-832c-cc683e3607b2
md"""
This package is in the Julia General Registry. In the Julia REPL, run the following code and follow the prompts:
"""

# ╔═╡ 99842416-3d0a-4def-aab9-731e2768b8c4
md"""
```julia
import Pkg
Pkg.add("Kneedle")
```
"""

# ╔═╡ 6de9b334-c487-4823-a08c-4166698967b8
md"""
Access the functionality of the package in your code by including the following line:
"""

# ╔═╡ ba5912d5-a2e7-4604-9cc5-28fbb6241ca1
md"""
# Quick Start
"""

# ╔═╡ 239cacee-2597-435f-add5-3aa057d291ec
md"""
Find a knee automatically using `kneedle(x, y)`:
"""

# ╔═╡ c3b80fa6-4ccc-4a2d-8e5c-7211814c1485
begin
	x, y = Testers.CONCAVE_INC  # an example data set
	kr = kneedle(x, y) 			# kr is a `KneedleResult`
	knees(kr) 					# [2], therefore a knee is detected at x = 2
end

# ╔═╡ 1e80ecea-7d79-4059-9a87-858c0c935dea
md"""
In order to use the plotting functionality, a Makie backend is required. For this example, this amounts to including the line `using CairoMakie`. This provides access to the function `viz(x, y, kr; kwargs...)`:
"""

# ╔═╡ bd7ee494-4952-48d4-945a-51ae69750757
md"""
We can then make the plot:
"""

# ╔═╡ fb718bd8-454e-44ae-b17b-ba20e89a09ed
viz(x, y, kr, show_data_smoothed = false)

# ╔═╡ b62b3349-bece-4c4a-8d90-d9f2b4ed14d7
md"""
# Tutorial
"""

# ╔═╡ 4e08d4bd-38d4-422b-a9a6-8757e549ff1f
md"""
## Automated detection of a single knee
"""

# ╔═╡ 630b4f66-1b23-4349-a95f-bca9548b45ba
md"""
Kneedle.jl is capable of automatically detecting the shape of the input knee. This works best when there is only one knee. The submodule `Testers` contains four datasets for each possible knee shape. We can use `kneedle` to find the knees and the `viz!` function to plot them all on in the same Makie figure.
"""

# ╔═╡ 1d6d6dcf-b326-4853-9327-2d8d4b49a30d
let
	x1, y1 = Testers.CONCAVE_INC; kr1 = kneedle(x1, y1)
	x2, y2 = Testers.CONCAVE_DEC; kr2 = kneedle(x2, y2)
	x3, y3 = Testers.CONVEX_INC; kr3 = kneedle(x3, y3)
	x4, y4 = Testers.CONVEX_DEC; kr4 = kneedle(x4, y4)

	set_theme!(theme_latexfonts())
	fig = Figure()
	ax1 = Axis(fig[1, 1], xlabel = L"x", ylabel = L"y", title = "Concave Increasing")
	viz!(ax1, x1, y1, kr1, show_data_smoothed=false)
	ax2 = Axis(fig[1, 2], xlabel = L"x", ylabel = L"y", title = "Concave Decreasing")
	viz!(ax2, x2, y2, kr2, show_data_smoothed=false)
	ax3 = Axis(fig[2, 1], xlabel = L"x", ylabel = L"y", title = "Convex Increasing")
	viz!(ax3, x3, y3, kr3, show_data_smoothed=false)
	ax4 = Axis(fig[2, 2], xlabel = L"x", ylabel = L"y", title = "Convex Decreasing")
	viz!(ax4, x4, y4, kr4, show_data_smoothed=false)

	fig
end

# ╔═╡ 6362117c-9c75-45fb-93cb-c90cdddde3e9
md"""
## Detection of knees of a given shape
"""

# ╔═╡ 59ad1ba7-a5c9-41d7-ad9b-14e775a54e09
md"""
We may use `kneedle(x, y, shape)` to attempt to detect knees of the given `shape`.

There are four possible knee/elbow shapes in consideration. If a kneedle function takes shape as an argument, it should be one of these.

- concave increasing: `"|¯"` or `"concave_inc"`

- convex decreasing: `"|_"` or `"convex_dec"`

- concave decreasing: `"¯|"` or `"concave_dec"`

- convex increasing: `"_|"` or `"convex_inc"`

Note that the symbol `¯` is entered by typing `\highminus<TAB>`
"""

# ╔═╡ 6772952c-f55d-43f9-af23-bd55e3abc9ca
let
	# Using the shape specification:
	x, y = Testers.CONCAVE_INC 
	kneedle(x, y, "concave_inc") |> knees
end

# ╔═╡ 30d677a1-d224-4361-b239-cb9a5ef80a3f
let
	# Using the pictoral specification:
	x, y = Testers.CONCAVE_INC 
	kneedle(x, y, "|¯") |> knees
end

# ╔═╡ 01ffc4e6-0eb1-458d-a06e-10041745dac8
let
	# This finds no knees of the requested shape because there are none!
	x, y = Testers.CONCAVE_INC 
	kneedle(x, y, "concave_dec") |> knees
end

# ╔═╡ 653ab1fc-fbb4-4c5f-b649-06a6c83233dc
md"""
## Dealing with noisy data
"""

# ╔═╡ 15825daf-ee71-4e08-9a6c-858372475de1
md"""
To simulate a noisy data source, we will use the function `Testers.double_bump()`. This generates a data set from a sum of two Normal CDFs. We will set the amplitude of one of them to zero first so that we only have to deal with a single knee. First we examine the noiseless data and find a knee of shape `"|¯"`.
"""

# ╔═╡ 3e987a4b-b9ec-4aa7-993d-60f1cf32f60e
let
	x_1, y_1 = Testers.double_bump(A2 = 0.0, noise_level = 0.0);
	kr = kneedle(x_1, y_1, "|¯")
	@info knees(kr)
	viz(x_1, y_1, kr, show_data_smoothed=false)
end

# ╔═╡ 556517bc-6747-4c03-b796-3d735ad583e3
md"""
Now let us add noise and try the same calculation
"""

# ╔═╡ 72f19479-05f5-41ab-9875-8f971ddec619
begin
	Random.seed!(1234) # reproducible randomness
	x_1noise, y_1noise = Testers.double_bump(A2 = 0.0, noise_level = 0.05)
	nothing
end

# ╔═╡ 49b7238e-c04e-46ba-8f94-878bc91297e6
let
	viz(x_1noise, y_1noise, kneedle(x_1noise, y_1noise, "|¯"), show_data_smoothed=false)
end

# ╔═╡ e542ce7d-0030-4492-b287-a68b6c53f119
md"""
The algorithm has far too much detection. This is controlled by the `S` kwarg to `kneedle`. The higher `S` is, the less detection. We will increase `S` to see the effect:
"""

# ╔═╡ ad86a047-4995-4002-8d81-c28748e56487
let
	kr = kneedle(x_1noise, y_1noise, "|¯", S = 10.0)
	@info knees(kr)
	viz(x_1noise, y_1noise, kr, show_data_smoothed=false)
end

# ╔═╡ 4dfc03de-d242-4ab0-abf5-98f77d6cfa65
md"""
We recover the noiseless knee but still with some additional artifacts. Increasing `S` further "settles" into an incorrect location:
"""

# ╔═╡ 200aca58-2b61-4ab5-a63b-a9375122ca64
let
	kr = kneedle(x_1noise, y_1noise, "|¯", S = 18.0)
	@info knees(kr)
	viz(x_1noise, y_1noise, kr, show_data_smoothed=false)
end

# ╔═╡ 32c75005-2884-40bf-9e70-737f79b40bbb
md"""
To handle this, we can use the `smoothing` kwarg to `kneedle`. `smoothing` refers to the amount of smoothing via interpolation that is applied to the data before knee detection. If `smoothing` == nothing, it will be bypassed entirely. If `smoothing` ∈ [0, 1], this parameter is passed directly to Loess.jl via its span parameter. Generally, higher `smoothing` results in less detection.
"""

# ╔═╡ fa2d353c-1160-4810-8dfd-851d192c5ac2
let
	kr = kneedle(x_1noise, y_1noise, "|¯", smoothing = 0.5)
	@info knees(kr)
	viz(x_1noise, y_1noise, kr, show_data_smoothed=true)
end

# ╔═╡ 2f944526-26bc-4224-8253-9a2101245889
md"""
This is much closer to the original knee location and we can still obtain resonable results even with very noisy data:
"""

# ╔═╡ e0b8d187-db13-4230-927b-c7f9da340062
begin
	Random.seed!(1234) # reproducible randomness
	x_1noise_high, y_1noise_high = Testers.double_bump(A2 = 0.0, noise_level = 0.20)
	nothing
end

# ╔═╡ f3d50c40-78f0-4560-b3c3-05e0b1179e6d
let
	kr = kneedle(x_1noise_high, y_1noise_high, "|¯", smoothing = 0.7)
	@info knees(kr)
	viz(x_1noise_high, y_1noise_high, kr, show_data_smoothed=true)
end

# ╔═╡ 801bb8ec-d605-4c54-a913-469e0d40a43d
md"""
## Finding a given number of knees
"""

# ╔═╡ a2785447-64c0-4d0d-93a7-ac599e3e14fa
md"""
To avoid the tedious process of guessing `S` or `smoothing`, one can provide the exact number of knees to search for. This works by bisecting either S (if `scan_type == :S`) or smoothing (if `scan_type == :smoothing`). Instead of finding `smoothing = 0.7` manually as in the last example, we can simply pass `1` knee and `scan_type = :smoothing` to `kneedle:
"""

# ╔═╡ 8e4755cf-f2aa-41d0-a589-d2653a5154ca
let
	kr = kneedle(x_1noise_high, y_1noise_high, "|¯", 1, scan_type = :smoothing)
	@info knees(kr)
	viz(x_1noise_high, y_1noise_high, kr, show_data_smoothed=true)
end

# ╔═╡ 43c68b71-cd5c-4185-ac6a-3926ca357fa4
md"""
The results are not identical as the bisection does not guarantee the minimum `smoothing` (and less smoothing does not always mean greater accuracy in knee location).
"""

# ╔═╡ 9d4e03a5-c9fc-4fc5-b121-1f88710f2780
md"""
We demonstrate this functionality further with a true double knee:
"""

# ╔═╡ 3b0080ef-6398-4106-960a-8dc0ec074864
let
	x_2, y_2 = Testers.double_bump(noise_level = 0.0)
	kr = kneedle(x_2, y_2, "|¯", 2)
	viz(x_2, y_2, kr)
end

# ╔═╡ 7dd9931e-8b3e-4928-b4c4-ffc9cbe6efd3
md"""
And again with noise:
"""

# ╔═╡ 0ef236c7-4cf8-424e-b32b-187ee5b71f25
let
	x_2, y_2 = Testers.double_bump(noise_level = 0.3)
	kr = kneedle(x_2, y_2, "|¯", 2, scan_type = :smoothing)
	viz(x_2, y_2, kr)
end

# ╔═╡ b60e5d82-8ba6-4bd3-a471-5fec6353da69
md"""
# Docstrings
"""

# ╔═╡ 1a6cfb27-b5d6-46b3-8f48-399fae9247c3
details("kneedle", @doc kneedle)

# ╔═╡ faaf42c4-e817-441c-b3db-8ec562e15323
details("KneedleResult", @doc KneedleResult)

# ╔═╡ 98a9b4cb-8fd9-480c-b1ce-418672e0441a
details("viz", @doc viz)

# ╔═╡ 671cfa97-f929-4cf4-8790-221d1ff1c6bc
details("viz!", @doc viz!)

# ╔═╡ 09000615-a7d7-421b-8444-113821058b96
details("Testers.double_bump", @doc Testers.double_bump)

# ╔═╡ c598e8c8-3d74-4946-ac16-ab757942f2da
details("Testers.CONCAVE_INC", @doc Testers.CONCAVE_INC)

# ╔═╡ 0ba861bf-0908-427b-8f2e-48be6d93842b
details("Testers.CONCAVE_DEC", @doc Testers.CONCAVE_DEC)

# ╔═╡ c50f5165-5d33-4479-801d-4925b60a84a6
details("Testers.CONVEX_INC", @doc Testers.CONVEX_INC)

# ╔═╡ 5428c5da-0111-4d97-8b3d-71a78b6b9d7d
details("Testers.CONVEX_DEC", @doc Testers.CONVEX_DEC)

# ╔═╡ 9ec18ec5-1aae-4689-b7f1-693d52cdec5b
md"""
# References
"""

# ╔═╡ 90ce7418-2a74-433b-9ae9-ca87e2b48027
md"""
[^1]: Satopaa, Ville, et al. *Finding a "kneedle" in a haystack: Detecting knee points in system behavior.* 2011 31st international conference on distributed computing systems workshops. IEEE, 2011.
"""

# ╔═╡ 384711a6-d7cb-4d69-a790-2f3d808aa5d8
md"""
---
---
---
"""

# ╔═╡ ae55f28c-7aac-11ef-0320-f11cdad35bfe
md"""
# Utilities
"""

# ╔═╡ 53873f99-598e-4136-affa-572f4ee2d4d3
md"""
This section contains tools to ensure the documentation works correctly; it is not part of the documentation itself.
"""

# ╔═╡ edd49b23-42bc-41cf-bfef-e1538fcdd924
begin
	@info "Setting notebook width."
	html"""
	<style>
		main {
			margin: 0 auto;
			max-width: 2000px;
	    	padding-left: 5%;
	    	padding-right: 5%;
		}
	</style>
	"""
end

# ╔═╡ 027d8aab-8c50-40cd-b887-fe4f877152bd
TableOfContents(depth = 2)

# ╔═╡ 269ad618-ce01-4d06-b0ce-e01a60dedfde
HTML("""
<!-- the wrapper span -->
<div>
	<button id="myrestart" href="#">Restart</button>
	
	<script>
		const div = currentScript.parentElement
		const button = div.querySelector("button#myrestart")
		const cell= div.closest('pluto-cell')
		console.log(button);
		button.onclick = function() { restart_nb() };
		function restart_nb() {
			console.log("Restarting Notebook");
		        cell._internal_pluto_actions.send(                    
		            "restart_process",
                            {},
                            {
                                notebook_id: editor_state.notebook.notebook_id,
                            }
                        )
		};
	</script>
</div>
""")

# ╔═╡ Cell order:
# ╟─1d5ffaa0-224b-4587-b7ae-859a26512cc3
# ╟─14bbc45a-621e-4b88-a821-0ba87083adc2
# ╟─3f40fc7d-4bb4-4763-b03c-f32d23ee3b48
# ╟─3638014c-ed4f-4c50-a91c-edf3db6fc97d
# ╟─9b5823a0-2f97-464a-929a-0596dc6a99a2
# ╟─74fc8395-26cf-4595-ac96-abecf7273d6c
# ╟─ec2763fd-6d65-4d61-832c-cc683e3607b2
# ╟─99842416-3d0a-4def-aab9-731e2768b8c4
# ╟─6de9b334-c487-4823-a08c-4166698967b8
# ╠═a70f7664-47b1-43c2-93aa-4a8e3886e38f
# ╟─ba5912d5-a2e7-4604-9cc5-28fbb6241ca1
# ╟─239cacee-2597-435f-add5-3aa057d291ec
# ╠═c3b80fa6-4ccc-4a2d-8e5c-7211814c1485
# ╟─1e80ecea-7d79-4059-9a87-858c0c935dea
# ╠═efaedc36-961b-4476-9a72-cca18ac7f385
# ╟─bd7ee494-4952-48d4-945a-51ae69750757
# ╠═fb718bd8-454e-44ae-b17b-ba20e89a09ed
# ╟─b62b3349-bece-4c4a-8d90-d9f2b4ed14d7
# ╟─4e08d4bd-38d4-422b-a9a6-8757e549ff1f
# ╟─630b4f66-1b23-4349-a95f-bca9548b45ba
# ╠═1d6d6dcf-b326-4853-9327-2d8d4b49a30d
# ╟─6362117c-9c75-45fb-93cb-c90cdddde3e9
# ╟─59ad1ba7-a5c9-41d7-ad9b-14e775a54e09
# ╠═6772952c-f55d-43f9-af23-bd55e3abc9ca
# ╠═30d677a1-d224-4361-b239-cb9a5ef80a3f
# ╠═01ffc4e6-0eb1-458d-a06e-10041745dac8
# ╟─653ab1fc-fbb4-4c5f-b649-06a6c83233dc
# ╟─15825daf-ee71-4e08-9a6c-858372475de1
# ╠═3e987a4b-b9ec-4aa7-993d-60f1cf32f60e
# ╟─556517bc-6747-4c03-b796-3d735ad583e3
# ╠═72f19479-05f5-41ab-9875-8f971ddec619
# ╠═49b7238e-c04e-46ba-8f94-878bc91297e6
# ╟─e542ce7d-0030-4492-b287-a68b6c53f119
# ╠═ad86a047-4995-4002-8d81-c28748e56487
# ╟─4dfc03de-d242-4ab0-abf5-98f77d6cfa65
# ╠═200aca58-2b61-4ab5-a63b-a9375122ca64
# ╟─32c75005-2884-40bf-9e70-737f79b40bbb
# ╠═fa2d353c-1160-4810-8dfd-851d192c5ac2
# ╟─2f944526-26bc-4224-8253-9a2101245889
# ╠═e0b8d187-db13-4230-927b-c7f9da340062
# ╠═f3d50c40-78f0-4560-b3c3-05e0b1179e6d
# ╟─801bb8ec-d605-4c54-a913-469e0d40a43d
# ╟─a2785447-64c0-4d0d-93a7-ac599e3e14fa
# ╠═8e4755cf-f2aa-41d0-a589-d2653a5154ca
# ╟─43c68b71-cd5c-4185-ac6a-3926ca357fa4
# ╟─9d4e03a5-c9fc-4fc5-b121-1f88710f2780
# ╠═3b0080ef-6398-4106-960a-8dc0ec074864
# ╟─7dd9931e-8b3e-4928-b4c4-ffc9cbe6efd3
# ╠═0ef236c7-4cf8-424e-b32b-187ee5b71f25
# ╟─b60e5d82-8ba6-4bd3-a471-5fec6353da69
# ╟─1a6cfb27-b5d6-46b3-8f48-399fae9247c3
# ╟─faaf42c4-e817-441c-b3db-8ec562e15323
# ╟─98a9b4cb-8fd9-480c-b1ce-418672e0441a
# ╟─671cfa97-f929-4cf4-8790-221d1ff1c6bc
# ╟─09000615-a7d7-421b-8444-113821058b96
# ╟─c598e8c8-3d74-4946-ac16-ab757942f2da
# ╟─0ba861bf-0908-427b-8f2e-48be6d93842b
# ╟─c50f5165-5d33-4479-801d-4925b60a84a6
# ╟─5428c5da-0111-4d97-8b3d-71a78b6b9d7d
# ╟─9ec18ec5-1aae-4689-b7f1-693d52cdec5b
# ╟─90ce7418-2a74-433b-9ae9-ca87e2b48027
# ╟─384711a6-d7cb-4d69-a790-2f3d808aa5d8
# ╟─ae55f28c-7aac-11ef-0320-f11cdad35bfe
# ╟─53873f99-598e-4136-affa-572f4ee2d4d3
# ╟─edd49b23-42bc-41cf-bfef-e1538fcdd924
# ╟─120250f8-5689-443d-bf99-dca7e1b41a82
# ╠═027d8aab-8c50-40cd-b887-fe4f877152bd
# ╟─269ad618-ce01-4d06-b0ce-e01a60dedfde
