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
# file: scripts/blas_threads.jl
# purpose: does the number of OpenBLAS threads per solve change the thread
#          scaling of the batch? runInjectionBatch with blas_threads 1, 2
#          and 8 on threads (8 and 24 workers) and on processes (24
#          workers), 264 load scenarios (20 percent band, seed 1), median of
#          3 calls after one uncounted first call, GC pause on.
# usage: julia -t 24 --project=. scripts/blas_threads.jl <out.csv> <case>   (case file from data/)
using Sparlectra, LinearAlgebra, Printf, Statistics, Libdl
const OPENBLAS_LIB = filter(l -> occursin("openblas", lowercase(l.libname)), BLAS.get_config().loaded_libs)[1].libname
out, name = ARGS[1], ARGS[2]
QUIET = OutputConfig(logfile_results = :off, console_summary = false, startup_latency_hint = false)
p = joinpath(dirname(@__DIR__), "data", name * ".m")
net = Sparlectra.import_case(p, SparlectraConfig(output = QUIET)).net
sc = random_load_scenarios(net, 264; seed = 1)
start_batch_processes!(24)
new = !isfile(out)
open(out, "a") do io
  new && println(io, "case,executor,k,blas_threads,N,median_s,ms_per_scenario,blas_default,openblas_config")
  cfg = unsafe_string(ccall(Libdl.dlsym(Libdl.dlopen(OPENBLAS_LIB), :openblas_get_config64_), Ptr{UInt8}, ()))
  for (ex, k) in ((:threads, 8), (:threads, 24), (:processes, 24)), b in (1, 2, 8)
    run() = runInjectionBatch(net, sc; executor = ex, max_processes = k, parallel_max_tasks = k, parallel_min_work_items = 1, blas_threads = b)
    run()
    ts = [(@elapsed run()) for _ in 1:3]
    m = median(ts)
    @printf(io, "%s,%s,%d,%d,%d,%.4f,%.3f,%d,%s\n", name, ex, k, b, length(sc), m, 1000 * m / length(sc), BLAS.get_num_threads(), replace(cfg, "," => ";"))
    flush(io)
    @printf(stderr, "%s %s k=%d blas=%d: %.3f ms per scenario\n", name, ex, k, b, 1000 * m / length(sc))
  end
end
