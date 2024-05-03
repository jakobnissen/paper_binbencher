# Effect of incomplete genomes
using CairoMakie
using BinBencherBackend

function add_header(path::AbstractString)
    header = "clustername\tcontigname"
    data = open(read, path)
    if !startswith(String(data[1:min(length(data), 50)]), header)
        data = [codeunits(header); b"\n"; data]
    end
    IOBuffer(data)
end

ref = Reference("results/reasm_ref.json")
split_bins = Binning(
    add_header("results/vambout_asm/vae_clusters.tsv"),
    ref;
    binsplit_separator='C'
)

gs_ref = Reference("raw/reference.json")
gs_bins = Binning("results/vambout/split_header.tsv", gs_ref)


(stats, gs_stats) = map((split_bins, gs_bins)) do binning
    map(binning.bins) do bin
        isempty(bin.genomes) && return nothing
        (genome, stats) = last(sort!(collect(bin.genomes); by=i -> last(i).asmsize))
        amber_recall = stats.asmsize / genome.assembly_size
        real_recall = stats.asmsize / genome.genome_size
        precision = recall_precision(genome, bin).precision
        (;genome, bin=bin.name, amber_recall, real_recall, precision)
    end
end

plt = let
    ((xs_asm, ys_asm), (xs_gs, ys_gs)) = map((stats, gs_stats)) do stat
        v = filter(!isnothing, stat)
        ([i.amber_recall for i in v], [i.real_recall for i in v])
    end

    f = Figure()
    alpha = 0.25
    xticks = 0.0:0.25:1.0
    yticks = xticks
    limits = (0, 1, 0, 1)

    scatter(f[1, 1], xs_gs, ys_gs; color=:black, alpha, axis=(;
        limits, xticks, yticks,
        title="Gold standard assembly",
        ylabel="Recall relative to genome size",
    )
    )
    scatter(f[1, 2], xs_asm, ys_asm; color=:black, alpha, axis=(;
    limits, xticks, yticks,
        title="metaSPAdes assembly",

    ))
    Label(f[1,1:2, Bottom()], "Recall relative to assembled fraction of genome"; padding=(0, 0, 0, 30))
    f
end

v = filter(stats) do s
    !isnothing(s) &&
    s.real_recall < 0.5 &&
    s.amber_recall > 0.90
end |> length

v = filter(stats) do s
    !isnothing(s) &&
    abs(s.real_recall - s.amber_recall) ≥ 0.1
end |> length


save("/tmp/unasm_recall.svg", plt)
