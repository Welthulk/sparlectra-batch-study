#!/bin/sh
# Copyright 2026 Udo Schmitz
# Licensed under the Apache License, Version 2.0 (see LICENSE).
# file: scripts/run_all.sh
# purpose: the CPU measurements of the study in the order they were run on
#          2026-11-22: the processes against threads table (24 workers, 70k
#          16, about 256 scenarios, 5 repeats), the executor crossover (24
#          workers, 24, 72 and 264 scenarios) and the OpenBLAS threads per
#          solve. Results go to results/new_*.csv; then
#          julia scripts/evaluate.jl reads the files named in it.
#          The GPU table comes from benchmark/gpu/batch_study_gpu.jl of
#          Sparlectra 1.3.0 (needs CUDA.jl and CUDSS.jl and an NVIDIA GPU):
#            REPEATS=5 SEED=1 START=net STRATEGIES=sequential NS=256 RAMP=0 \
#            CPU_TIMED=0 julia -t 24 --project=benchmark/gpu \
#            benchmark/gpu/batch_study_gpu.jl case_ACTIVSg70k
#          Run nothing else on the machine while measuring.
# usage:   sh scripts/run_all.sh
set -u
cd "$(dirname "$0")/.." || exit 2
julia --project=. scripts/download_cases.jl || exit 1
for c in case1354pegase case2869pegase case6495rte case9241pegase case_ACTIVSg10k case_ACTIVSg25k case_ACTIVSg70k
do
  k=24; m=11
  if [ "$c" = case_ACTIVSg70k ]; then k=16; m=16; fi
  for ex in threads processes
  do
    julia -t 24 --project=. scripts/cpu_batch.jl results/new_cpu_scaling_n256.csv "$c" "$ex" "$m" 5 "$k"
  done
done
for c in case118 case300 case_ACTIVSg500 case1354pegase case1888rte case_ACTIVSg2000 case2869pegase
do
  for m in 1 3 11
  do
    for ex in threads processes
    do
      julia -t 24 --project=. scripts/cpu_batch.jl results/new_crossover.csv "$c" "$ex" "$m" 5 24
    done
  done
done
for c in case2869pegase case9241pegase
do
  julia -t 24 --project=. scripts/blas_threads.jl results/new_blas_threads.csv "$c"
done
