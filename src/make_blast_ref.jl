using FASTX

CAMIPATH = "/home/databases/bioinf_db/CAMI2/HUMAN/Gastrointestinal/short_read"
SAMPLES = [0, 1, 2, 3, 4, 5, 9, 10, 11, 12]

# Parse OTU => path
otu_to_filename = open("$CAMIPATH/genome_to_id.tsv") do io
    Iterators.map(eachline(io)) do line
        =>(split(line, '\t')...)
    end |> Dict
end

mkpath("tmp/blast/refs")
for sample in SAMPLES
    nonzero_filenames = open("$CAMIPATH/abundance$(sample).tsv") do io
        result = String[]
        for line in eachline(io)
            (otu, abstring) = split(line, '\t')
            abundance = parse(Float64, abstring)
            iszero(abundance) && continue
            push!(result, basename(otu_to_filename[otu]))
        end
        result
    end

    FASTAWriter(open("tmp/blast/refs/$(sample).fna", "w")) do writer
        for filename in nonzero_filenames
            FASTAReader(open("$CAMIPATH/genomes/$(filename)"); copy=false) do reader
                for record in reader
                    write(writer, record)
                end
            end
        end
    end
end
