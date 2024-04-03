using BinBencherBackend
ref = Reference("raw/reference.json")
bins = Binning("results/vambout/split_header.tsv", ref)
println(n_recovered(bins, 0.9, 0.95))
