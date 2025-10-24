### A Pluto.jl notebook ###
# v0.20.19

using Markdown
using InteractiveUtils

# ╔═╡ 120250f8-5689-443d-bf99-dca7e1b41a82
# ╠═╡ show_logs = false
begin
	import Pkg
	# Pkg.develop(path = "/Users/gbonner/Desktop/Repositories/Kneedle.jl/")
	Pkg.add(url="https://github.com/70Gage70/Kneedle.jl", rev="master")
	Pkg.add([
		"CairoMakie", 
		"BlackBoxOptim",
		"PlutoUI"])
	using PlutoUI
	import Random
end

# ╔═╡ a70f7664-47b1-43c2-93aa-4a8e3886e38f
using Kneedle

# ╔═╡ efaedc36-961b-4476-9a72-cca18ac7f385
using CairoMakie

# ╔═╡ a052e378-a475-4432-9a7f-69182ab2f975
# ╠═╡ show_logs = false
using BlackBoxOptim

# ╔═╡ 1d5ffaa0-224b-4587-b7ae-859a26512cc3
md"""
# Kneedle.jl
"""

# ╔═╡ 9b5823a0-2f97-464a-929a-0596dc6a99a2
md"""
!!! info ""
	This is the documentation for the package [Kneedle.jl](https://github.com/70Gage70/Kneedle.jl). The documentation is powered by a [Pluto.jl](https://plutojl.org/) notebook. 
	
	Note that executed code shows the result *above* the code!
	
	Kneedle.jl is a [Julia](https://julialang.org/) implementation of the Kneedle[^1] knee-finding algorithm. This detects "corners" (or "knees", "elbows", ...) in a dataset `(x, y)`.

	**Features**
	- Exports one main function `kneedle` with the ability to select the shape and number of knees to search for.
	- Built-in data smoothing from [Loess.jl](https://github.com/JuliaStats/Loess.jl).
	- [Makie](https://docs.makie.org/stable/) extension for quick visualization.
"""

# ╔═╡ 966454cc-11a6-486f-b124-d3f9d3ee0591
TableOfContents(title = "Contents", depth = 2, aside= false)

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
We find one knee in a sensible position but still with some additional artifacts. Increasing `S` further "settles" into an incorrect location:
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

# ╔═╡ a2592b4d-24c7-48f6-9ee8-b9207a63bd46
begin
	Random.seed!(1234) # reproducible randomness
	x_2, y_2 = Testers.double_bump(noise_level = 0.0)
	x_2noise, y_2noise = Testers.double_bump(noise_level = 0.3)
	nothing
end

# ╔═╡ 3b0080ef-6398-4106-960a-8dc0ec074864
let
	kr = kneedle(x_2, y_2, "|¯", 2)
	viz(x_2, y_2, kr)
end

# ╔═╡ 7dd9931e-8b3e-4928-b4c4-ffc9cbe6efd3
md"""
And again with noise. Keep in mind that for very noisy data we still might have to set the parameter that we aren't scanning according to the source.
"""

# ╔═╡ 0ef236c7-4cf8-424e-b32b-187ee5b71f25
let
	kr = kneedle(x_2noise, y_2noise, "|¯", 2, scan_type = :S, smoothing = 0.4)
	viz(x_2noise, y_2noise, kr)
end

# ╔═╡ ab8a3ae9-3c3f-4f6d-a4cc-ce23f734e66f
let
	kr = kneedle(x_2noise, y_2noise, "|¯", 2, scan_type = :smoothing, S = 0.1)
	viz(x_2noise, y_2noise, kr)
end

# ╔═╡ f1374349-bcfc-40dc-9dd5-20b2e1deea4f
md"""
## Application to sparse regression
"""

# ╔═╡ 94256cdc-1f6e-45e5-8674-17feac55b044
md"""
Linear regression finds coefficients $\xi$ such that $y ≈ X ξ$ for a feature matrix $X$ and target $y$. *Sparse* linear regression further asks that the coefficient vector $\xi$ be sparse, i.e that it contain as many zeros as possible. This can be thought of as asking to represent $y$ by just the most relevant features of $X$.

Many sparse regression algorithms involve a thresholding parameter, say $\lambda$, that determines the minimum size of allowed coefficients. The idea is that small $\lambda$ implies that $X \xi$ is accurate but not sparse, whereas large $\lambda$ implies that $X \xi$ is sparse but not accurate. The idea is therefore to pick the largest $\lambda$ possible while still having a sufficiently accurate solution. On a plot of model error vs. $\lambda$, this is equivalent to asking for the `_|` knee.

The following data come from a sparse regression problem solved offline.
"""

# ╔═╡ 8cc49a7c-3fbc-4271-b486-39d4043bf339
details("Data", md"""
```julia
λs = [0.1, 0.14384498882876628, 0.20691380811147897, 0.29763514416313186, 0.4281332398719394, 0.6158482110660264, 0.8858667904100826, 1.2742749857031337, 1.8329807108324359, 2.636650898730358, 3.79269019073225, 5.455594781168519, 7.847599703514613, 11.28837891684689, 16.237767391887218, 23.357214690901223, 33.59818286283783, 48.32930238571752, 69.51927961775606, 100.0]

errs = [10.934290106930245, 10.83733683826938, 11.017433337213713, 11.124893613300706, 11.119853842082296, 11.099548594837454, 11.03789948291263, 16.205849291523638, 16.206016168361213, 16.204933621558062, 16.205591636093704, 16.205684051603743, 16.20568226625062, 16.228735841057354, 16.23024949820953, 16.23017241763306, 16.229714642370798, 16.22987500373123, 16.229503091439568, 16.230329157796838]
```
""")

# ╔═╡ e8db1bdd-872f-4b83-b6f9-5d491e5b9b36
md"""
We see that `kneedle` correctly finds the largest $\lambda$ that has small error.
"""

# ╔═╡ c00b2622-36b1-4759-9056-7e4104780b52
md"""
Occasionally, a simpler tool is required. In the situation above, all we really needed was the ``x`` coordinate of the largest jump. For these situations, `scan_type = :jump` is provided. Let us consider another sparse regression problem.
"""

# ╔═╡ 2fa7cec0-5305-49e7-a723-1cf78ab1e99e
details("Data", md"""
```julia
λs_jump = [0.0001, 0.0001268961003167922, 0.00016102620275609394, 0.00020433597178569417, 0.0002592943797404667, 0.00032903445623126676, 0.00041753189365604, 0.0005298316906283707, 0.0006723357536499335, 0.0008531678524172806, 0.001082636733874054, 0.0013738237958832624, 0.0017433288221999873, 0.002212216291070448, 0.0028072162039411755, 0.003562247890262444, 0.004520353656360245, 0.005736152510448681, 0.007278953843983154, 0.009236708571873866, 0.0117210229753348, 0.01487352107293511, 0.018873918221350976, 0.02395026619987486, 0.03039195382313198, 0.03856620421163472, 0.04893900918477494, 0.06210169418915616, 0.07880462815669913, 0.1]

errs_jump = [0.34630490893779403, 0.3456230803320486, 0.34629815348076226, 0.3451340844905556, 0.34638953229304026, 0.34598864701127763, 0.3457970619366877, 0.34575439193946284, 0.3464065358126432, 0.34576762328554683, 0.34545299139743757, 0.34588755467961135, 0.34630038200136376, 0.3512185727589153, 0.3533948843113959, 0.35275407567486977, 0.3532250681905738, 0.35273217424391967, 0.35342246447895154, 0.3532491653004756, 0.35230967224647336, 0.35248107019160135, 0.3523814242281752, 0.35320080164445666, 0.3531298923951794, 0.353116209580546, 0.35352032530282024, 0.3531660763893177, 0.3534225134384502, 0.35208274637778114]
```
""")

# ╔═╡ 4bd3b4ac-2994-4f9f-954b-c60d4d83716c
md"""
In cases such as this with one large jump, the `:jump` scan type will outperform the stock kneedle algorithm.
"""

# ╔═╡ d55a1989-3f50-4564-8a7f-7751f6c33724
md"""
## Three-segment knee finding
"""

# ╔═╡ b8c3c3cd-3106-4d91-9b2b-b3ae7abb2ce6
md"""
`Kneedle.jl` includes one additional algorithm which formulates an optimization problem. This method regresses `(x, y)` onto a piecewise linear function with three segments, and then applies the core kneedle algorithm on the resulting data. This is a kind of smoothing that may have better performance for "jumpy" data. To acceess the algorithm, the package [BlackBoxOptim.jl](https://github.com/robertfeldt/BlackBoxOptim.jl) must be loaded:
"""

# ╔═╡ f9b0ddf5-d5d9-46ee-ace5-92f5e32cb17e
md"""
We can use `scan_type = :tri` to use this algorithm, ensuring to set the number of knees to `1`. We see that this algorithm accurately solves all of the previous problems at the expense of speed. Solving the optimization problem is somewhat slower than the core kneedle algorithm.
"""

# ╔═╡ d59cea7e-6031-4a66-aaa1-a198646b1747
let
	Random.seed!(1234)
	kr = kneedle(x_1noise_high, y_1noise_high, "|¯", 1, scan_type = :tri)
	@info knees(kr)
	viz(x_1noise_high, y_1noise_high, kr, show_data_smoothed=true)
end

# ╔═╡ b60e5d82-8ba6-4bd3-a471-5fec6353da69
md"""
# Docstrings
"""

# ╔═╡ 1a6cfb27-b5d6-46b3-8f48-399fae9247c3
details("kneedle", @doc kneedle)

# ╔═╡ faaf42c4-e817-441c-b3db-8ec562e15323
details("KneedleResult", @doc KneedleResult)

# ╔═╡ 975a39fa-f4ad-418a-b2c2-98af962a1037
details("knees", @doc knees)

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

# ╔═╡ b1c6f598-17df-4d9a-a3e4-2e21addd1ed1
md"""
# End of Documentation
"""

# ╔═╡ 384711a6-d7cb-4d69-a790-2f3d808aa5d8
md"""
---
---
---
"""

# ╔═╡ ae55f28c-7aac-11ef-0320-f11cdad35bfe
# md"""
# # Utilities
# """

# ╔═╡ 53873f99-598e-4136-affa-572f4ee2d4d3
# md"""
# !!! danger ""
# 	This section contains tools to ensure the documentation works correctly; it is not part of the documentation itself.
# """

# ╔═╡ edd49b23-42bc-41cf-bfef-e1538fcdd924
begin
	# @info "Setting notebook width."
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

# ╔═╡ a35b1234-a722-442b-8969-7635a28556ff
begin
	# @info "Defining data"
	
	λs = [0.1, 0.14384498882876628, 0.20691380811147897, 0.29763514416313186, 0.4281332398719394, 0.6158482110660264, 0.8858667904100826, 1.2742749857031337, 1.8329807108324359, 2.636650898730358, 3.79269019073225, 5.455594781168519, 7.847599703514613, 11.28837891684689, 16.237767391887218, 23.357214690901223, 33.59818286283783, 48.32930238571752, 69.51927961775606, 100.0]
	errs = [10.934290106930245, 10.83733683826938, 11.017433337213713, 11.124893613300706, 11.119853842082296, 11.099548594837454, 11.03789948291263, 16.205849291523638, 16.206016168361213, 16.204933621558062, 16.205591636093704, 16.205684051603743, 16.20568226625062, 16.228735841057354, 16.23024949820953, 16.23017241763306, 16.229714642370798, 16.22987500373123, 16.229503091439568, 16.230329157796838]

	λs_jump = [0.0001, 0.0001268961003167922, 0.00016102620275609394, 0.00020433597178569417, 0.0002592943797404667, 0.00032903445623126676, 0.00041753189365604, 0.0005298316906283707, 0.0006723357536499335, 0.0008531678524172806, 0.001082636733874054, 0.0013738237958832624, 0.0017433288221999873, 0.002212216291070448, 0.0028072162039411755, 0.003562247890262444, 0.004520353656360245, 0.005736152510448681, 0.007278953843983154, 0.009236708571873866, 0.0117210229753348, 0.01487352107293511, 0.018873918221350976, 0.02395026619987486, 0.03039195382313198, 0.03856620421163472, 0.04893900918477494, 0.06210169418915616, 0.07880462815669913, 0.1]
	errs_jump = [0.34630490893779403, 0.3456230803320486, 0.34629815348076226, 0.3451340844905556, 0.34638953229304026, 0.34598864701127763, 0.3457970619366877, 0.34575439193946284, 0.3464065358126432, 0.34576762328554683, 0.34545299139743757, 0.34588755467961135, 0.34630038200136376, 0.3512185727589153, 0.3533948843113959, 0.35275407567486977, 0.3532250681905738, 0.35273217424391967, 0.35342246447895154, 0.3532491653004756, 0.35230967224647336, 0.35248107019160135, 0.3523814242281752, 0.35320080164445666, 0.3531298923951794, 0.353116209580546, 0.35352032530282024, 0.3531660763893177, 0.3534225134384502, 0.35208274637778114]
	nothing
end

# ╔═╡ b3563637-f40d-4c11-ab15-5c60c365162c
let
	fig = Figure(); ax = Axis(fig[1, 1], xlabel = L"\log_{10} \, \lambda", ylabel = "error")
	log10λs = log10.(λs)
	kr = kneedle(log10λs, errs, "_|")
	viz!(ax, log10λs, errs, kr, show_data_smoothed=false)
	Legend(fig[2, 1], ax, orientation = :horizontal)
	fig
end

# ╔═╡ 00f2a928-a6aa-4a78-a9fe-e74202c2ce36
let
	fig = Figure(); ax = Axis(fig[1, 1], xlabel = L"\log_{10} \, \lambda", ylabel = "error")
	log10λs = log10.(λs_jump)
	kr = kneedle(log10λs, errs_jump, "_|")
	viz!(ax, log10λs, errs_jump, kr, show_data_smoothed=false)
	Legend(fig[2, 1], ax, orientation = :horizontal, merge = true)
	fig
end

# ╔═╡ 8e0ac392-362d-4e08-9c78-3d4362142a16
let
	fig = Figure(); ax = Axis(fig[1, 1], xlabel = L"\log_{10} \, \lambda", ylabel = "error")
	log10λs = log10.(λs_jump)
	kr = kneedle(log10λs, errs_jump, "_|", 1, scan_type = :jump)
	viz!(ax, log10λs, errs_jump, kr, show_data_smoothed=false)
	Legend(fig[2, 1], ax, orientation = :horizontal, merge = true)
	fig
end

# ╔═╡ f2026780-e480-422f-a90b-373d3883d7d5
let
	Random.seed!(1234)
	fig = Figure(); ax = Axis(fig[1, 1], xlabel = L"\log_{10} \, \lambda", ylabel = "error")
	log10λs = log10.(λs)
	kr = kneedle(log10λs, errs, "_|", 1, scan_type = :tri)
	viz!(ax, log10λs, errs, kr, show_data_smoothed=true)
	Legend(fig[2, 1], ax, orientation = :horizontal)
	fig
end

# ╔═╡ c4172294-3317-42e7-b922-e9d4edd24830
let
	Random.seed!(1234)
	fig = Figure(); ax = Axis(fig[1, 1], xlabel = L"\log_{10} \, \lambda", ylabel = "error")
	log10λs = log10.(λs_jump)
	kr = kneedle(log10λs, errs_jump, "_|", 1, scan_type = :tri)
	viz!(ax, log10λs, errs_jump, kr, show_data_smoothed=true)
	Legend(fig[2, 1], ax, orientation = :horizontal, merge = true)
	fig
end

# ╔═╡ Cell order:
# ╟─1d5ffaa0-224b-4587-b7ae-859a26512cc3
# ╟─9b5823a0-2f97-464a-929a-0596dc6a99a2
# ╟─966454cc-11a6-486f-b124-d3f9d3ee0591
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
# ╠═a2592b4d-24c7-48f6-9ee8-b9207a63bd46
# ╠═3b0080ef-6398-4106-960a-8dc0ec074864
# ╟─7dd9931e-8b3e-4928-b4c4-ffc9cbe6efd3
# ╠═0ef236c7-4cf8-424e-b32b-187ee5b71f25
# ╠═ab8a3ae9-3c3f-4f6d-a4cc-ce23f734e66f
# ╟─f1374349-bcfc-40dc-9dd5-20b2e1deea4f
# ╟─94256cdc-1f6e-45e5-8674-17feac55b044
# ╟─8cc49a7c-3fbc-4271-b486-39d4043bf339
# ╠═b3563637-f40d-4c11-ab15-5c60c365162c
# ╟─e8db1bdd-872f-4b83-b6f9-5d491e5b9b36
# ╟─c00b2622-36b1-4759-9056-7e4104780b52
# ╟─2fa7cec0-5305-49e7-a723-1cf78ab1e99e
# ╠═00f2a928-a6aa-4a78-a9fe-e74202c2ce36
# ╟─4bd3b4ac-2994-4f9f-954b-c60d4d83716c
# ╠═8e0ac392-362d-4e08-9c78-3d4362142a16
# ╟─d55a1989-3f50-4564-8a7f-7751f6c33724
# ╟─b8c3c3cd-3106-4d91-9b2b-b3ae7abb2ce6
# ╠═a052e378-a475-4432-9a7f-69182ab2f975
# ╟─f9b0ddf5-d5d9-46ee-ace5-92f5e32cb17e
# ╠═d59cea7e-6031-4a66-aaa1-a198646b1747
# ╠═f2026780-e480-422f-a90b-373d3883d7d5
# ╠═c4172294-3317-42e7-b922-e9d4edd24830
# ╟─b60e5d82-8ba6-4bd3-a471-5fec6353da69
# ╟─1a6cfb27-b5d6-46b3-8f48-399fae9247c3
# ╟─faaf42c4-e817-441c-b3db-8ec562e15323
# ╟─975a39fa-f4ad-418a-b2c2-98af962a1037
# ╟─98a9b4cb-8fd9-480c-b1ce-418672e0441a
# ╟─671cfa97-f929-4cf4-8790-221d1ff1c6bc
# ╟─09000615-a7d7-421b-8444-113821058b96
# ╟─c598e8c8-3d74-4946-ac16-ab757942f2da
# ╟─0ba861bf-0908-427b-8f2e-48be6d93842b
# ╟─c50f5165-5d33-4479-801d-4925b60a84a6
# ╟─5428c5da-0111-4d97-8b3d-71a78b6b9d7d
# ╟─9ec18ec5-1aae-4689-b7f1-693d52cdec5b
# ╟─90ce7418-2a74-433b-9ae9-ca87e2b48027
# ╟─b1c6f598-17df-4d9a-a3e4-2e21addd1ed1
# ╟─384711a6-d7cb-4d69-a790-2f3d808aa5d8
# ╟─ae55f28c-7aac-11ef-0320-f11cdad35bfe
# ╟─53873f99-598e-4136-affa-572f4ee2d4d3
# ╟─edd49b23-42bc-41cf-bfef-e1538fcdd924
# ╟─120250f8-5689-443d-bf99-dca7e1b41a82
# ╟─269ad618-ce01-4d06-b0ce-e01a60dedfde
# ╟─a35b1234-a722-442b-8969-7635a28556ff
