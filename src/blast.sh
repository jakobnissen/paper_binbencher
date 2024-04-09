SAMPLES=("0" "1" "2" "3" "4" "5" "9" "10" "11" "12");

module load tools;
module load perl;
module load ncbi-blast/2.15.0+;

mkdir -p tmp/blast/results
blastn -query results/spades/${SAMPLES[$PBS_ARRAYID]}_2kbp.fna -subject tmp/blast/refs/${SAMPLES[$PBS_ARRAYID]}.fna -outfmt 6 -max_target_seqs 10 -max_hsps 5 -perc_identity 90 -out tmp/blast/results/${SAMPLES[$PBS_ARRAYID]}.tsv -num_threads 8
