using FASTX

for subdir in filter!(isdir, readdir("results/spades"; join=true))
    sample = basename(subdir)
    FASTAWriter(open("results/spades/$(sample)_2kbp.fna", "w")) do writer
        prefix = "S$(sample)C"
        FASTAReader(open("$subdir/contigs.fasta"); copy=false) do reader
            for (i, record) in enumerate(reader)
                seqsize(record) < 2_000 && continue
                newname = prefix * string(i)
                new_record = FASTARecord(newname, sequence(record))
                write(writer, new_record)
            end
        end
    end
end

open("results/spades/catalogue.fna", "w") do out
    for filename in filter!(!isdir, readdir("results/spades"))
        filename == "catalogue.fna" && continue
        open("results/spades/$(filename)") do inp
            write(out, inp)
        end
    end
end
