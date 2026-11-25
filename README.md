# Batches of power flows on one workstation: processes, threads and a GPU

A measurement study with [Sparlectra.jl](https://github.com/Welthulk/Sparlectra.jl)
1.3.0 on batches of AC power flows (N-1 cases, load scenarios).

**Article:** [`article/article.md`](article/article.md), also as
[`article/article.pdf`](article/article.pdf).

## Results in short

- A batch runs 2.7 to 4.2 times faster on 24 cores when each worker is a
  separate Julia process instead of a thread of one process, on every
  network measured from 1354 to 70 000 buses.
- The threads queue at the memory allocator lock of OpenBLAS inside the
  sparse LU (UMFPACK). Separate processes have their own OpenBLAS. More
  OpenBLAS threads per solve do not help.
- A GPU with the cuDSS sparse solver is up to 4.2 times faster than the CPU
  with processes (ACTIVSg70k: 43 ms instead of 182 ms per scenario), from
  about 3000 buses on.
- GPU and CPU results agree to 2e-12 pu; repeated runs are bit-identical.

## Contents

| Path | What |
|---|---|
| `article/` | the article (Markdown, PDF) and its figures with the plot script |
| `results/` | the measured CSV files and `evaluation.md` written from them |
| `results/lock_evidence/` | profile, system call counts and fault probes behind section 3 |
| `scripts/download_cases.jl` | downloads the MATPOWER case files and checks their SHA-256 |
| `scripts/cpu_batch.jl` | CPU measurement: threads or worker processes |
| `scripts/blas_threads.jl` | OpenBLAS threads per solve |
| `scripts/evaluate.jl` | tables from the CSV files |
| `scripts/run_all.sh` | the CPU measurements in the order they were run |

## Reproduce

Julia 1.12 or later. The project pins Sparlectra 1.3.0 from the General
registry.

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. scripts/download_cases.jl
sh scripts/run_all.sh
julia scripts/evaluate.jl
```

`run_all.sh` writes its CSV files as `results/new_*.csv`; rename them to the
names in `evaluate.jl` to evaluate a new run. The GPU table is measured with
`benchmark/gpu/batch_study_gpu.jl` of Sparlectra 1.3.0 (see the comment in
`run_all.sh`). The numbers of the article come from an Intel Core Ultra 9 285
(8 P and 16 E cores), 124 GB RAM and an NVIDIA RTX PRO 4000 Blackwell SFF;
other machines give other numbers.

## Data

The case files are not part of this repository. `scripts/download_cases.jl`
loads them from the [MATPOWER](https://matpower.org) release 8.1 on GitHub.
They keep the licenses stated in their headers and in MATPOWER:

- `case1354pegase`, `case2869pegase`, `case9241pegase` (PEGASE) and
  `case1888rte`, `case6495rte` (RTE): C. Josz, S. Fliscounakis, J. Maeght
  and P. Panciatici, https://arxiv.org/abs/1603.01533, and for PEGASE also
  S. Fliscounakis et al., IEEE Trans. Power Systems 28(4), 2013. Licensed
  under CC BY 4.0 (see the file headers).
- `case_ACTIVSg500`, `case_ACTIVSg2000`, `case_ACTIVSg10k`,
  `case_ACTIVSg25k`, `case_ACTIVSg70k`: A. B. Birchfield, T. Xu,
  K. M. Gegner, K. S. Shetye and T. J. Overbye, IEEE Trans. Power Systems
  32(4), 2017 (ACTIVSg70k also 2018). Licensed under CC BY 4.0 (see the
  file headers).
- `case118`, `case300`: IEEE test cases as distributed with MATPOWER.

When publishing results based on these cases, cite MATPOWER and the sources
named in the case headers.

## Citing

The study:

```bibtex
@misc{schmitz_batch_study_2026,
  title  = {Batches of power flows on one workstation: processes, threads and a GPU},
  author = {Schmitz, Udo},
  year   = {2026},
  url    = {https://github.com/Welthulk/sparlectra-batch-study}
}
```

Sparlectra (version 1.3.0 was measured):

```bibtex
@software{sparlectra_jl,
  title  = {Sparlectra.jl: A Power-Flow and State-Estimation Framework in Julia},
  author = {Schmitz, Udo},
  year   = {2026},
  url    = {https://github.com/Welthulk/Sparlectra.jl}
}
```

MATPOWER: R. D. Zimmerman, C. E. Murillo-Sanchez, and R. J. Thomas,
"MATPOWER: Steady-State Operations, Planning and Analysis Tools for Power
Systems Research and Education," IEEE Transactions on Power Systems, 26(1),
12-19, 2011.

## Acknowledgments

The author thanks SOPTIM AG for sponsoring the workstation used for the
measurements and for its support of this work.

## License

Scripts: Apache License 2.0 (`LICENSE`). Article, figures and result data:
CC BY 4.0 (`LICENSE-CC-BY-4.0.md`).
