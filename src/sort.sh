SAMPLES=("0" "1" "2" "3" "4" "5" "9" "10" "11" "12");

module load tools;
module load samtools/1.18;

samtools sort -@ 3 -m 4G -o results/bam/${SAMPLES[$PBS_ARRAYID]}.sorted.bam results/bam/${SAMPLES[$PBS_ARRAYID]}.bam
