using BinBencherBackend
using BinBencher
using JSON3

const BB = BinBencher
const BBB = BinBencherBackend
const SAMPLES = [0, 1, 2, 3, 4, 5, 9, 10, 11, 12]

refjson = open("raw/reference.json") do io
    JSON3.read(io, BB.ReferenceJSON)
end

function parse_blast(io::IO)
    Iterators.map(eachline(io)) do line
        # 'qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore', which is equivalent to the keyword 'std'
        fields = split(line, '\t')
        (;
            qseqid = String(fields[1]),
            sseqid = String(fields[2]),
            ident = parse(Float64, fields[3]) / 100,
            qstart = parse(Int, fields[7]),
            qend = parse(Int, fields[8]),
            sstart = parse(Int, fields[9]),
            send = parse(Int, fields[10]),
            bitscore = parse(Float64, fields[12]),
        )
    end |> collect
end

const SeqT = Vector{Tuple{String, Int64, Vector{Tuple{String, Int64, Int64}}}}

sequences::SeqT = let
    result = SeqT()
    for sample in SAMPLES
        hits = open(parse_blast, "results/blast/results/$(sample).tsv")
        
    end
    result
end

new = BB.ReferenceJSON(
    2,
    refjson.genomes,
    sequences,
    refjson.taxmaps,
)

open(io -> BB.save(io, new), "results/asm_ref.json", "w")
