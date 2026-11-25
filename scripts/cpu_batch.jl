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
# file: scripts/cpu_batch.jl
# purpose: the CPU measurement of the study. runInjectionBatch of
#          Sparlectra on one case, executor threads (start Julia with
#          -t 24) or processes (a pool of max(ks) worker processes, started
#          once before the first batch and timed apart), k workers, m load
#          scenarios per worker (N = m k, 20 percent band, seed 1), R
#          counted repeats after one uncounted warm-up batch. GC pause and
#          one BLAS thread per solve are the Sparlectra 1.3.0 defaults.
#          One CSV row per batch; throughput_per_s = N / wall time.
# usage: julia -t 24 --project=. scripts/cpu_batch.jl <out.csv> <case> <threads|processes> [m] [R] [ks]
#        ks as a comma list, default 24; the case file comes from data/
using Sparlectra, Printf, Dates, Statistics, Distributed

const QUIET = OutputConfig(logfile_results = :off, console_summary = false, startup_latency_hint = false)

function main(args)
  out, name, ex = args[1], args[2], Symbol(args[3])
  m = length(args) >= 4 ? parse(Int, args[4]) : 11
  R = length(args) >= 5 ? parse(Int, args[5]) : 5
  ks = length(args) >= 6 ? parse.(Int, split(args[6], ",")) : [24]
  path = joinpath(dirname(@__DIR__), "data", name * ".m")
  isfile(path) || error("$(path) is missing; run julia scripts/download_cases.jl first")
  net = Sparlectra.import_case(path, SparlectraConfig(output = QUIET)).net
  version = string(pkgversion(Sparlectra))
  t_pool = 0.0
  if ex === :processes
    t = time_ns()
    start_batch_processes!(maximum(ks))
    t_pool = (time_ns() - t) / 1e9
  end
  new = !isfile(out)
  open(out, "a") do io
    new && println(io, "sparlectra,case,executor,k,N,rep,mode,wall_s,throughput_per_s,all_converged,iterations_sum,main_maxrss_gb,workers_maxrss_gb,pool_start_s,julia_threads")
    for k in ks
      N = m * k
      sc = random_load_scenarios(net, N; seed = 1)
      for rep = 0:R
        t = time_ns()
        r = runInjectionBatch(net, sc; executor = ex, max_processes = k, parallel_max_tasks = k, parallel_min_work_items = 1)
        wall = (time_ns() - t) / 1e9
        rep == 0 && continue   # warm-up (compile, first transfer)
        st = r.stats
        wrss = st[:executor] === :processes ? sum(remotecall_fetch(Sys.maxrss, w) for w in batch_process_ids()[1:k]) / 2^30 : 0.0
        @printf(io, "%s,%s,%s,%d,%d,%d,%s,%.4f,%.3f,%s,%d,%.2f,%.2f,%.2f,%d\n", version, name, ex, k, N, rep, st[:executor], wall, N / wall,
          all(r.converged), sum(r.iterations), Sys.maxrss() / 2^30, wrss, t_pool, Threads.nthreads())
        flush(io)
      end
      @printf(stderr, "%s %s %s k=%d done\n", Dates.format(now(), "HH:MM:SS"), name, ex, k)
    end
  end
  ex === :processes && stop_batch_processes!()
end

Base.invokelatest(main, ARGS)
