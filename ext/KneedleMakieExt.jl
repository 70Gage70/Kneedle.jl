module KneedleMakieExt

using Kneedle
using Makie
using PrecompileTools: @compile_workload
import Random

function Kneedle.viz(
    x::AbstractVector{<:Real},
    y::AbstractVector{<:Real},
    kr::KneedleResult; 
    show_data::Bool = true,
    show_data_smoothed::Bool = true,
    show_knees::Bool = true,
    linewidth::Real = 2.0)

    set_theme!(theme_latexfonts())
    fig = Figure()
    ax = Axis(fig[1, 1], xlabel = L"x", ylabel = L"y")

    show_data && lines!(ax, x, y, color = :black, label = "Data", linewidth = linewidth)
    show_data_smoothed && lines!(ax, kr.x_smooth, kr.y_smooth, color = :red, linewidth = linewidth, label = "Smoothed Data")
    if show_knees
        for knee_x in knees(kr)
            vlines!(ax, knee_x, color = :blue, linewidth = linewidth, label = "Knee")
        end
    end

    Legend(fig[2, 1], ax, orientation = :horizontal, merge = true)
    rowsize!(fig.layout, 1, Aspect(1, 0.5))
    resize_to_layout!(fig)
    fig
end

function Kneedle.viz!(
    ax::Makie.Axis,
    x::AbstractVector{<:Real},
    y::AbstractVector{<:Real},
    kr::KneedleResult; 
    show_data::Bool = true,
    show_data_smoothed::Bool = true,
    show_knees::Bool = true,
    linewidth::Real = 2.0)

    show_data && lines!(ax, x, y, color = :black, label = "Data", linewidth = linewidth)
    show_data_smoothed && lines!(ax, kr.x_smooth, kr.y_smooth, color = :red, linewidth = linewidth, label = "Smoothed Data")
    if show_knees
        for knee_x in knees(kr)
            vlines!(ax, knee_x, color = :blue, linewidth = linewidth, label = "Knee")
        end
    end

    return nothing
end

@compile_workload begin
    Random.seed!(1234)
    x, y = Testers.double_bump(noise_level = 0.1)
    kr = kneedle(x, y, smoothing = 0.1)
    viz(x, y, kr)
    fig = Figure(); ax = Axis(fig[1, 1]);
    viz!(ax, x, y, kr)
end

end # module