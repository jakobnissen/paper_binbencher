using CairoMakie
using BinBencherBackend

ifilter(f) = x -> Iterators.filter(f, x)
imap(f) = x -> Iterators.map(f, x)

ref = Reference("raw/reference.json")

genome_sims = open("results/fastani.tsv") do io
    map(eachline(io)) do line
        otu(p) = first(splitext(basename(p)))
        (a, b, ident, _...) = split(line, '\t')
        (otu(a), otu(b)) => parse(Float64, ident)/100
    end |> Dict
end

# Turns out FastANI doesn't necessarily compute A -> B
# to be the same as B -> A. We use the minimum of the two,
# to be conservative (since the point we want to make is
# that the similarity can be very high)
deduplicated_sims = let
    d = empty(genome_sims)
    for (k, v) in genome_sims
        (a, b) = minmax(k...)

        # We also compute ANI to itself, skip those
        a == b && continue
        k1 = (a, b)
        k2 = (b, a)
        k == k1 || k == k2
        haskey(d, k1) && continue
        d[k1] = min(get(genome_sims, k1, 1.0), get(genome_sims, k2, 1.0))
    end
    d
end

by_species = let
    otu_to_species = Dict(g.name => g.parent for g in genomes(ref))
    res = Dict()
    for ((a, b), v) in deduplicated_sims
        s1 = otu_to_species[a]
        s2 = otu_to_species[b]
        s1 === s2 || error()
        push!(get!(Vector, res, s1), v)
    end
    res
end

count(values(by_species)) do v
    sum(v) / length(v) ≥ 0.999
end

n_above(x) = count(i -> i ≥ x, values(deduplicated_sims))

print("Total pairs: ", length(deduplicated_sims))
print("Pairs ≥ 99% ANI: ", n_above(0.99))
print("Pairs ≥ 99.9% ANI: ", n_above(0.999))
print("Pairs ≥ 99.99% ANI: ", n_above(0.9999))

hst = let
    v = [sum(i)/length(i) for i in values(by_species)]
    # If not true, the plotting ranges below needs to be updated
    @assert minimum(v) > 0.88
    # filter!(i -> i ≥ 0.99, v)
    hist(
        v;
        color=:black,
        bins=0.88:0.005:1.0,
        axis=(;
            xlabel="Average nucleotide identity (ANI)",
            ylabel="Number of species",
            xticks=(0.88:0.01:1.0),
            limits=(0.88, 1.0, 0, 22)
        )
    )
end

save("/tmp/ani.svg", hst)

# Number of bins which are declared as contaminated,
# but contamination is within 97% identity.
closely_related_genomes = let
    res = Set{Tuple{Genome, Genome}}()
    genome_by_name = Dict(g.name => g for g in genomes(ref))
    for ((gn1, gn2), val) in deduplicated_sims
        val ≥ 0.99 || continue
        g1 = genome_by_name[gn1]
        g2 = genome_by_name[gn2]
        push!(res, (g1, g2))
        push!(res, (g2, g1))
    end
    res
end

bins = Binning("results/vambout/split_header.tsv", ref)

neighbors = let
    N = Dict(g => Set{Genome}([g]) for g in genomes(ref))
    for (a, b) in closely_related_genomes
        push!(N[a], b)
        push!(N[b], a)
    end
    N
end

complete_bins_w_genomes = map(bins.bins) do bin
    (bin, [g for g in keys(bin.genomes) if recall_precision(g, bin).recall ≥ 0.9]) # TODO
end
filter!(complete_bins_w_genomes) do (b, gs)
    !isempty(gs)
end
        
precisions = map(complete_bins_w_genomes) do (bin, genomes)
    # Get the genome with the largest precision
    genome = sort!(genomes; by=g -> recall_precision(g, bin).precision)[end]
    genome_neighbors = push!(neighbors[genome], genome)
    precision = recall_precision(genome, bin).precision

    # What would the precision be if we didn't consider any genomes
    # with ANI ≥ 0.99 to be contamination?
    tp = bin.genomes[genome].asmsize
    fp = Iterators.filter(bin.sequences) do seq
        targets = last(ref.targets[ref.target_index_by_name[seq.name]])
        all(targets) do (source, _)
            source.genome ∉ genome_neighbors
        end
    end |> (i -> sum(length, i; init=0))
    micro_precision = tp / (tp + fp)
    species_precision = recall_precision(genome.parent, bin).precision
    @assert micro_precision ≥ precision
    @assert species_precision ≥ precision
    (;precision, species_precision, micro_precision)
end

two_panel_fig = let
    genome_v = let
        v = filter(i -> i.precision != 1.0, precisions)
        [clamp((i.micro_precision - i.precision) / (1 - i.precision), eps(0.0), 1.0 - eps(1.0)) for i in v]
    end
    species_v = let
        v = filter(i -> i.species_precision != 1.0, precisions)
        [clamp((i.micro_precision - i.species_precision) / (1 - i.species_precision), eps(0.0), 1.0 - eps(1.0)) for i in v]
    end
    
    f = Figure()
    pos = f[1, 1]
    bins = 0:0.05:1
    hist(pos, genome_v; bins, color=:black, axis=(;
        xticks=(0.0:0.2:1.0),
        limits=(0, 1, 0, 70),
        title="Genome level benchmarking",
    ))

    pos2 = f[2, 1]
    hist(pos2, species_v; bins, color=:black, axis=(;
    xticks=(0.0:0.2:1.0),
    limits=(0, 1, 0, 70),
    title="Species level benchmarking",
))
    Label(f[2,1, Bottom()], "Fraction of contamination of complete bins that is microdiversity"; padding=(0, 0, 0, 30))
    f
end
save("/tmp/precision.svg", two_panel_fig)

contaminated = collect(filter(i -> i.precision != 1, precisions))
count(i -> i.micro_precision ≥ 0.99999, contaminated)

contaminated = collect(filter(i -> i.species_precision != 1, precisions))
count(i -> i.micro_precision ≥ 0.99999, contaminated)
