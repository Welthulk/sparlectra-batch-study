# Copyright 2026 Udo Schmitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# file: article/figures/article_figures.jl
# purpose: the figures of the GPU study article from the numbers of its
#          tables, Sparlectra 1.3.0 (results/evaluation.md;
#          time per scenario in ms converted to scenarios per second). Palette: categorical slots 1 to 3 of the default
#          dataviz palette (blue processes, orange threads, aqua GPU), plus a
#          marker shape per series so identity is not color alone.
# usage: julia --project=<an environment with CairoMakie> article/figures/article_figures.jl article/figures
using CairoMakie
out = ARGS[1]
blue, orange, aqua = colorant"#2a78d6", colorant"#eb6834", colorant"#1baf7a"
ink, muted, grid = colorant"#1f1f1e", colorant"#6b6b66", colorant"#e6e6e2"
set_theme!(Theme(fontsize = 15, font = "DejaVu Sans",
  Axis = (xgridcolor = grid, ygridcolor = grid, xminorgridvisible = false, yminorgridvisible = false,
          leftspinecolor = muted, bottomspinecolor = muted, topspinevisible = false, rightspinevisible = false,
          xtickcolor = muted, ytickcolor = muted, xlabelcolor = ink, ylabelcolor = ink, titlecolor = ink, titlefont = :bold,
          titlealign = :left)))

names = ["1354", "2869", "6495", "9241", "10k", "25k", "70k"]
buses = [1354, 2869, 6495, 9241, 10000, 25000, 70000]
thr = 1000 ./ [4.88, 18.7, 24.8, 71.8, 51.6, 128, 532]   # scenarios/s, 24 workers (70k 16)
pro = 1000 ./ [1.49, 4.47, 9.09, 19.7, 15.5, 43.3, 182]
gpu = 1000 ./ [2.53, 4.55, 3.41, 9.78, 6.22, 13.0, 43.4]
ms(x) = 1000 ./ x

# figure 1: time per scenario against network size
f = Figure(size = (900, 560))
ax = Axis(f[1, 1], xscale = log10, yscale = log10, xlabel = "network size (buses)", ylabel = "time per scenario (ms, log scale)",
  title = "Time per power flow in a batch of about 256 scenarios", subtitle = "smaller is faster; CPU with 24 workers (70k: 16)",
  xticks = (buses[[1, 2, 4, 6, 7]], ["1354", "2869", "9241", "25 000", "70 000"]), yticks = [1, 3, 10, 30, 100, 300])
for (y, c, m, lab) in ((ms(thr), orange, :circle, "CPU, threads"), (ms(pro), blue, :rect, "CPU, processes"), (ms(gpu), aqua, :utriangle, "GPU (cuDSS)"))
  lines!(ax, buses, y; color = c, linewidth = 2)
  scatter!(ax, buses, y; color = c, marker = m, markersize = 11, strokecolor = :white, strokewidth = 1.5, label = lab)
  text!(ax, buses[end], y[end]; text = lab, color = ink, align = (:left, :center), offset = (10, 0), fontsize = 13)
end
xlims!(ax, 1000, 250000)
axislegend(ax; position = :lt, framevisible = false)
save(joinpath(out, "fig1_time_per_scenario.png"), f; px_per_unit = 2)

# figure 2: throughput against the number of workers (case9241pegase, N = k)
k = [1, 8, 16, 24]
tk = [3.18, 10.4, 11.2, 10.6]
pk = [3.22, 17.5, 26.1, 31.8]
f = Figure(size = (900, 520))
ax = Axis(f[1, 1], xlabel = "workers", ylabel = "scenarios per second", xticks = k,
  title = "Threads stop gaining after 8 workers (case9241pegase)", subtitle = "larger is faster; one scenario per worker")
lines!(ax, k, k .* tk[1]; color = muted, linestyle = :dash, linewidth = 1.5)
text!(ax, 10.5, 10.5 * tk[1]; text = "linear scaling", color = muted, align = (:left, :top), offset = (6, 0), fontsize = 12)
for (y, c, m, lab) in ((tk, orange, :circle, "threads"), (pk, blue, :rect, "processes"))
  lines!(ax, k, y; color = c, linewidth = 2)
  scatter!(ax, k, y; color = c, marker = m, markersize = 11, strokecolor = :white, strokewidth = 1.5, label = lab)
  text!(ax, k[end], y[end]; text = lab, color = ink, align = (:left, :center), offset = (10, 0), fontsize = 13)
end
xlims!(ax, 0, 28); ylims!(ax, 0, 40)
axislegend(ax; position = :lt, framevisible = false)
save(joinpath(out, "fig2_workers.png"), f; px_per_unit = 2)

# figure 3: speed-up factors against network size
f = Figure(size = (900, 520))
ax = Axis(f[1, 1], xscale = log10, xlabel = "network size (buses)", ylabel = "speed-up (times faster)",
  title = "How much faster: processes over threads, GPU over processes", subtitle = "above 1: faster; below 1: slower",
  xticks = (buses[[1, 2, 4, 6, 7]], ["1354", "2869", "9241", "25 000", "70 000"]))
hlines!(ax, [1.0]; color = muted, linewidth = 1.5, linestyle = :dash)
for (y, c, m, lab) in ((pro ./ thr, blue, :rect, "processes over threads"), (gpu ./ pro, aqua, :utriangle, "GPU over processes"))
  lines!(ax, buses, y; color = c, linewidth = 2)
  scatter!(ax, buses, y; color = c, marker = m, markersize = 11, strokecolor = :white, strokewidth = 1.5, label = lab)
end
xlims!(ax, 1000, 100000); ylims!(ax, 0, 5)
axislegend(ax; position = :lt, framevisible = false)
save(joinpath(out, "fig3_speedup.png"), f; px_per_unit = 2)
# figure 4: crossover on smaller networks, 264 scenarios, pool running
xb = [118, 300, 500, 1354, 1888, 2000, 2869]
xt = [0.334, 1.45, 1.54, 5.07, 5.63, 7.73, 19.0]
xp = [0.386, 1.42, 0.559, 1.49, 1.80, 2.55, 4.51]
f = Figure(size = (900, 540))
ax = Axis(f[1, 1], xscale = log10, yscale = log10, xlabel = "network size (buses)", ylabel = "time per scenario (ms, log scale)",
  title = "From about 1000 buses the processes win", subtitle = "smaller is faster; 264 scenarios, 24 workers, worker pool already running",
  xticks = (xb[[1, 2, 3, 4, 7]], ["118", "300", "500", "1354", "2869"]), yticks = [0.3, 1, 3, 10, 30])
vlines!(ax, [1000]; color = muted, linewidth = 1.5, linestyle = :dash)
text!(ax, 1000, 0.3; text = "1000 buses", color = muted, align = (:left, :bottom), offset = (6, 4), fontsize = 12)
for (y, c, m, lab) in ((xt, orange, :circle, "threads"), (xp, blue, :rect, "processes"))
  lines!(ax, xb, y; color = c, linewidth = 2)
  scatter!(ax, xb, y; color = c, marker = m, markersize = 11, strokecolor = :white, strokewidth = 1.5, label = lab)
  text!(ax, xb[end], y[end]; text = lab, color = ink, align = (:left, :center), offset = (10, 0), fontsize = 13)
end
xlims!(ax, 90, 6000)
axislegend(ax; position = :lt, framevisible = false)
save(joinpath(out, "fig4_crossover.png"), f; px_per_unit = 2)
println("figures written to ", out)
