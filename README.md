# Binbench
Code used to create the BinBencher paper

Author: Jakob Nybo Nissen
Date of creation: 2024-03-04

# Data dependencies
* raw.tar.gz: sha256sum=6ff7a53f6d6dfc2aaddb1b729479d63e15e23d219f9733380bba9177a80d3983
* Is available on Zenondo - search for BinBencher

# Software dependencies
* Julia 1.10.3 and related packages - see Manifest.toml for a complete list
* FastANI 1.34
* SPAdes 3.15.5
* NCBI BLAST 2.15.0
* Vamb 4.1.3
* Minimap2 2.24
* Samtools 1.18
* CheckM2 1.0.2 (results not used in paper)

# How to run
See the Git history for the files created, and run them in the order they have been created.

## Directory structure
* `raw`: Raw data, e.g. experimental data, or data from external research groups.
  Should not be modified at all.
* `src`: This directory contains code and scripts used to reproduce the results.
  The file `main.py` or `main.jl` should produce all results using only the data
  in directories `raw` and `choices`.
* `tmp`: Directory for throwaway analyses and intermediate results.
  Anything in this directory should be able to be deleted with no big loss
* `results`: For final analytic results. `main.jl/py` should write results to this
  directory, primarily
