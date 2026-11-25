# Measurements on Sparlectra 1.3.0

## 1. Time per scenario, about 256 scenarios, 24 workers (70k: 16)

Milliseconds per scenario (smaller is faster).

| Network | Threads ms | Processes ms | GPU ms | Processes faster than threads | GPU faster than processes |
|---|---|---|---|---|---|
| case1354pegase | 4.88 | 1.49 | 2.53 | 3.27 | 0.59 |
| case2869pegase | 18.7 | 4.47 | 4.55 | 4.18 | 0.98 |
| case6495rte | 24.8 | 9.09 | 3.41 | 2.73 | 2.67 |
| case9241pegase | 71.8 | 19.7 | 9.78 | 3.65 | 2.01 |
| case_ACTIVSg10k | 51.6 | 15.5 | 6.22 | 3.34 | 2.48 |
| case_ACTIVSg25k | 128 | 43.3 | 13 | 2.96 | 3.33 |
| case_ACTIVSg70k | 532 | 182 | 43.4 | 2.92 | 4.20 |

## 2. Executor crossover: threads against processes, 24 workers

Milliseconds per scenario without the pool start (the pool is started once per session); the last column is the batch size from which the processes win even when the batch pays the pool start itself.

| Network | N | Threads ms | Processes ms | Processes faster by | Pool start s | N from which a cold pool pays off |
|---|---|---|---|---|---|---|
| case118 | 24 | 0.703 | 0.338 | 2.08 | 6.03 | 16499 |
| case118 | 72 | 0.425 | 0.214 | 1.99 | 6.03 | 28560 |
| case118 | 264 | 0.334 | 0.386 | 0.87 | 6.03 | never |
| case300 | 24 | 1.93 | 3.63 | 0.53 | 6.15 | never |
| case300 | 72 | 1.53 | 1.5 | 1.02 | 6.15 | 245202 |
| case300 | 264 | 1.45 | 1.42 | 1.02 | 6.15 | 230165 |
| case_ACTIVSg500 | 24 | 2.8 | 0.878 | 3.18 | 6.12 | 3191 |
| case_ACTIVSg500 | 72 | 1.66 | 1.69 | 0.98 | 6.12 | never |
| case_ACTIVSg500 | 264 | 1.54 | 0.559 | 2.75 | 6.12 | 6256 |
| case1354pegase | 24 | 7.83 | 5.96 | 1.31 | 6.01 | 3221 |
| case1354pegase | 72 | 5.45 | 2.65 | 2.06 | 6.01 | 2144 |
| case1354pegase | 264 | 5.07 | 1.49 | 3.41 | 6.01 | 1676 |
| case1888rte | 24 | 9.25 | 3.64 | 2.54 | 6.14 | 1094 |
| case1888rte | 72 | 6.12 | 3.35 | 1.83 | 6.14 | 2217 |
| case1888rte | 264 | 5.63 | 1.8 | 3.12 | 6.14 | 1606 |
| case_ACTIVSg2000 | 24 | 11.6 | 9.18 | 1.27 | 5.98 | 2456 |
| case_ACTIVSg2000 | 72 | 7.86 | 3.39 | 2.32 | 5.98 | 1339 |
| case_ACTIVSg2000 | 264 | 7.73 | 2.55 | 3.04 | 5.98 | 1154 |
| case2869pegase | 24 | 24.6 | 12.1 | 2.03 | 6.01 | 482 |
| case2869pegase | 72 | 18.4 | 5.28 | 3.48 | 6.01 | 459 |
| case2869pegase | 264 | 19 | 4.51 | 4.21 | 6.01 | 414 |
