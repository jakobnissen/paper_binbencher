using CairoMakie
using BinBencherBackend

include("utils.jl")

# Four-panel histogram: Fraction of incompleteness already covered by the bin
# BB/AMBER and multi-split vs unsplit
function compute_redundant_recall(bin::Bin, total_bp_per_genome::Dict{Genome, Int})
    # Get the best genome for this bin according to AMBER
    (best_genome, total_bp) = let
        (g, s) = first(bin.genomes)
        (g, s.total_bp)
    end
    for (genome, stats) in bin.genomes
        if stats.total_bp > total_bp
            best_genome = genome
            total_bp = stats.total_bp
        end
    end

    amber_recall = total_bp / total_bp_per_genome[best_genome]
    missing_bp = total_bp_per_genome[best_genome] - total_bp
    missing_positions = best_genome.assembly_size - bin.genomes[best_genome].asmsize

    # This is not actually guaranteed, but I hope it doesn't happen
    @assert missing_positions ≤ missing_bp

    (;bin, genome=best_genome, amber_recall, recall=recall_precision(best_genome, bin).recall, missing_bp, missing_positions)
end

ref = Reference("raw/reference.json")
split_bins = Binning("results/vambout/split_header.tsv", ref)
unsplit_bins = Binning("results/vambout/unsplit_header.tsv", ref)

total_bp_per_genome = let
    seqs_by_genome = Dict(g => Set{Sequence}() for g in genomes(ref))
    for (seq, targets) in ref.targets
        for (source, span) in targets
            push!(seqs_by_genome[source.genome], seq)
        end
    end
    Dict(g => sum(length, v; init=0) for (g, v) in seqs_by_genome)
end

hst = let
    min_size = 200_000
    amber_split = let
        v = map(b -> compute_redundant_recall(b, total_bp_per_genome), split_bins.bins)
        filter!(i -> i.bin.breadth ≥ min_size, v)
        [clamp(1 - (i.missing_positions / i.missing_bp), 0, 1.0-eps(1.0)) for i in filter(i -> i.missing_bp > 0, v)]
    end
    amber_unsplit = let
        v = map(b -> compute_redundant_recall(b, total_bp_per_genome), unsplit_bins.bins)
        filter!(i -> i.bin.breadth ≥ min_size, v)
        [clamp(1 - (i.missing_positions / i.missing_bp), 0, 1.0-eps(1.0)) for i in filter(i -> i.missing_bp > 0, v)]
    end

    f = Figure()
    bins = 0:0.05:1
    hist(f[2, 1], amber_split; color=:black, bins, axis=(;
        xticks=(0.0:0.1:1.0),
        ylabel="Bins",
        title="Multi-split bins",
        limits=(0, 1, 0, 250),
    ))

    hist(f[1, 1], amber_unsplit; color=:black, bins, axis=(;
    xticks=(0.0:0.1:1.0),
    title="Bins not split by sample",
    ylabel="Bins",
    limits=(0, 1, 0, 60),
    ))
    Label(f[2,1, Bottom()], "Fraction of missing basepairs from bins ≥ 200 kbp\naccording to AMBER that are redundant"; padding=(0, 0, 0, 30))
    f
end
save("/tmp/redundant.svg", hst)

# Per-sample benchmarks with unsplit:
# We show that precision is overestimated
# Just compare AMBER to AMBER
samplewise = Dict{String, Dict{Int, NamedTuple}}()
for S in Utils.SAMPLES
    for (bin_name, tup) in open(
            Utils.parse_amber_output,
            "results/unsplit_samplewise/$S/bin_metrics.tsv"
        )
        get!(valtype(samplewise), samplewise, bin_name)[S] = tup
    end
end

together = open(
    Utils.parse_amber_output,
    "results/amber_all_unsplit/bin_metrics.tsv"
)

filtered_bin_names = filter(together) do (k, v)
    v.total_length ≥ 200_000
end |> keys |> Set

error_plot = let
    recall_errors = Float64[]
    precision_errors = Float64[]
    for k in filtered_bin_names
        gt = together[k]
        for (_, stats) in samplewise[k]
            push!(recall_errors, clamp(stats.recall - gt.recall, -1.0 + eps(-1.0), 1-eps(1.0)))
            push!(precision_errors, clamp(stats.precision - gt.precision, -1.0 + eps(-1.0), 1-eps(1.0)))
        end
    end
    @show length(recall_errors)

    f = Figure()
    bins = -1.025:0.05:1.025
    hist(f[1, 1], recall_errors; color=:black, bins, axis=(;
        limits=(-1, 1, 0, 450),
        ylabel="Bins",
        xlabel="Recall error",
        xticks=(-1.0:0.2:1.0)
    ))
    hist(f[2, 1], precision_errors; color=:black,  bins, axis=(;
        limits=(-1, 1, 0, 450),
        ylabel="Bins",
        xlabel="Precision error",
        xticks=(-1.0:0.2:1.0),
    ))
    f
end

save("/tmp/errors.svg", error_plot)
