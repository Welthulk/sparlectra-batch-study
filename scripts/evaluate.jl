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
# file: scripts/evaluate.jl
# purpose: tables of the study from the result CSVs: time per scenario in
#          milliseconds (smaller is faster) and speed-up factors for threads,
#          processes and the GPU at about 256 scenarios, and the executor
#          crossover (threads against processes at 24 workers for N = 24, 72,
#          264) with the batch size from which a cold worker pool pays off.
#          Writes results/evaluation.md. Standard library only.
# usage: julia scripts/evaluate.jl
using Statistics, Printf

const NEW = joinpath(dirname(@__DIR__), "results")
const CASES = ["case1354pegase", "case2869pegase", "case6495rte", "case9241pegase", "case_ACTIVSg10k", "case_ACTIVSg25k", "case_ACTIVSg70k"]
const XCASES = ["case118", "case300", "case_ACTIVSg500", "case1354pegase", "case1888rte", "case_ACTIVSg2000", "case2869pegase"]

function rows(path)
  out = Dict{String,String}[]
  isfile(path) || return out
  hdr = String[]
  for line in eachline(path)
    (isempty(line) || startswith(line, "#") || startswith(line, "Case:")) && continue
    f = split(line, ',')
    if f[1] in ("commit", "case")
      hdr = String.(f)
      continue
    end
    isempty(hdr) && continue
    push!(out, Dict(hdr[i] => String(f[i]) for i in 1:min(length(hdr), length(f))))
  end
  return out
end

num(r, k) = (v = tryparse(Float64, get(r, k, "")); v === nothing ? NaN : v)

# CPU: median throughput per (case, executor, N); pool start per (case, executor)
function cpu(path)
  t = Dict{Tuple{String,String,Int},Vector{Float64}}()
  pool = Dict{Tuple{String,String},Float64}()
  buses = Dict{String,Int}()
  for r in rows(path)
    get(r, "mode", "") in ("threads", "processes") || continue
    key = (r["case"], r["executor"], parse(Int, r["N"]))
    push!(get!(t, key, Float64[]), num(r, "throughput_per_s"))
    p = num(r, "pool_start_s")
    isfinite(p) && p > 0 && (pool[(r["case"], r["executor"])] = p)
  end
  return Dict(k => median(v) for (k, v) in t), pool
end

function gpu(path)
  t = Dict{String,Float64}()
  for r in rows(path)
    get(r, "start", "") == "net" && get(r, "status", "") == "ok" && get(r, "variant", "") == "sequential" && get(r, "N", "") == "256" || continue
    t[r["case"]] = num(r, "scen_per_s")
  end
  return t
end

ms(x) = x === nothing || !isfinite(x) ? "-" : (v = 1000 / x; v < 100 ? @sprintf("%.3g", v) : @sprintf("%.0f", v))
fx(x) = x === nothing || !isfinite(x) ? "-" : @sprintf("%.2f", x)
pick(d, c, ex) = (ks = [k for k in keys(d) if k[1] == c && k[2] == ex]; isempty(ks) ? nothing : d[ks[argmax([k[3] for k in ks])]])

function main()
  io = IOBuffer()
  println(io, "# Measurements on Sparlectra 1.3.0\n")

  cn, pn = cpu(joinpath(NEW, "cpu_scaling_n256.csv"))
  gn = gpu(joinpath(NEW, "batch_cold.csv"))

  println(io, "## 1. Time per scenario, about 256 scenarios, 24 workers (70k: 16)\n")
  println(io, "Milliseconds per scenario (smaller is faster).\n")
  println(io, "| Network | Threads ms | Processes ms | GPU ms | Processes faster than threads | GPU faster than processes |")
  println(io, "|---|---|---|---|---|---|")
  for c in CASES
    t, p, g = pick(cn, c, "threads"), pick(cn, c, "processes"), get(gn, c, nothing)
    println(io, "| $c | $(ms(t)) | $(ms(p)) | $(ms(g)) | $(fx(p === nothing || t === nothing ? nothing : p / t)) | $(fx(g === nothing || p === nothing ? nothing : g / p)) |")
  end
  println(io)

  xn, xpool = cpu(joinpath(NEW, "crossover.csv"))
  println(io, "## 2. Executor crossover: threads against processes, 24 workers\n")
  println(io, "Milliseconds per scenario without the pool start (the pool is started once per session); the last column is the batch size from which the processes win even when the batch pays the pool start itself.\n")
  println(io, "| Network | N | Threads ms | Processes ms | Processes faster by | Pool start s | N from which a cold pool pays off |")
  println(io, "|---|---|---|---|---|---|---|")
  for c in XCASES, n in (24, 72, 264)
    t, p = get(xn, (c, "threads", n), nothing), get(xn, (c, "processes", n), nothing)
    ps = get(xpool, (c, "processes"), NaN)
    breakeven = (t === nothing || p === nothing || !(p > t)) ? "never" : @sprintf("%.0f", ps / (1 / t - 1 / p))
    println(io, "| $c | $n | $(ms(t)) | $(ms(p)) | $(fx(t === nothing || p === nothing ? nothing : p / t)) | $(isfinite(ps) ? @sprintf("%.2f", ps) : "-") | $breakeven |")
  end

  path = joinpath(NEW, "evaluation.md")
  write(path, String(take!(io)))
  println("wrote ", path)
end

Base.invokelatest(main)
