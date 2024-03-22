using BinBencherBackend
using FASTX
using Serialization

CAMI_PATH = "/home/databases/bioinf_db/CAMI2/HUMAN/Gastrointestinal/short_read"

genome_name_to_filename = open(joinpath(CAMI_PATH, "genome_to_id.tsv")) do io
    d = Dict()
    for line in eachline(io)
        otu, path = split(line, '\t')
        d[otu] = basename(path)
    end
    d
end

# Of course this doesn't generically work, but having checked all the genomes
# manually, this is sufficient for Gastrointestinal
function is_genomic(rec::FASTARecord)
    n = lowercase(String(description(rec)))
    all(["conjugative", "plasmid", "phage"]) do j
        !occursin(j, n)
    end
end

# Remove plasmids etc from genomes before comparison
# We also create files in tmp/species that contain lists of FASTAs for each species
# with 2 or more genomes. This is what FastANI operates on
mkpath("tmp/species")
mkpath("tmp/modified_genomes")
ref = Reference("/home/projects/ku_00197/data/vamb/cami2_gi/reference.json")
for species in ref.clades[1]
    length(species.children) < 2 && continue
    children = [
        (i.name, joinpath(CAMI_PATH, "genomes", genome_name_to_filename[i.name]))
        for i in species.children
    ]
    for (name, path) in children
        outpath = "tmp/modified_genomes/$(name).fna"
        isfile(outpath) && continue
        FASTAWriter(open(outpath, "w")) do writer
            did_write = false
            FASTAReader(open(path)) do reader
                for record in reader
                    is_genomic(record) || continue
                    did_write = true
                    write(writer, record)
                end
            end
            did_write || error(name)
        end
    end

    open("tmp/species/$(species.name)", "w") do io
        for (name, _) in children
            println(io, "tmp/modified_genomes/$(name).fna")
        end
    end
end

# Spawn N threads that each run FastANI on each species, all-against-all
ch = Channel(Inf)
for i in enumerate(readdir("tmp/species", join=true))
    put!(ch, i)
end
close(ch)

lck = ReentrantLock()
Threads.@threads for _ in 1:Threads.nthreads()
    for (i, path) in ch
        out = "tmp_$(i).txt"
        stderr = "tmp_$(i).sterr"
    
        run(pipeline(`fastANI --rl $(path) --ql $(path) -o $(out)`, stderr=stderr))
        data = collect(eachline(out))
        @lock lck open("results/fastani.tsv", "a") do io
            for line in data
                println(io, line)
            end
        end
        rm(out)
        println(i)
    end
end

