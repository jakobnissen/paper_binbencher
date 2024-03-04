# Binbench
Runs for use in BinBencher paper

Binners: Vamb, SemiBin2
Datasets: 5 original CAMI2 (human, short read toy datasets)
Benchmarkers: BinBencher, AMBER, CheckM2

Author: Jakob Nybo Nissen
Date of creation: 2024-03-04

## Directory structure
* `raw`: Raw data, e.g. experimental data, or data from external research groups.
  Should not be modified at all.
* `src`: This directory contains code and scripts used to reproduce the results.
  The file `main.py` or `main.jl` should produce all results using only the data
  in directories `raw` and `choices`.
* `tmp`: Directory for throwaway analyses and intermediate results.
  Anything in this directory should be able to be deleted with no big loss
* `cache`: Also for intermediate results, but for content that is troublesome
  to recreate, e.g. results of long-running simuations or long-running computation
* `choices`: For files that are not raw files, but impossible to recreate automatically,
  because they rely on humans (you!) making judgement calls.
* `results`: For final analytic results. `main.jl/py` should write results to this
  directory, primarily
* `paper`: For results related to submission of any papers, e.g. manuscripts or
  publication-ready figures.
