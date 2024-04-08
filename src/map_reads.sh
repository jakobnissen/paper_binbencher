SAMPLES=("0" "1" "2" "3" "4" "5" "9" "10" "11" "12");

module load tools;
module load minimap2/2.24r1122;
module load samtools/1.18;

mkdir -p results/bam
# I have run this manually: minimap2 -d results/spades/catalogue.mmi results/spades/catalogue.fna
minimap2 -t 8 -ax sr results/spades/catalogue.mmi /home/databases/bioinf_db/CAMI2/HUMAN/Gastrointestinal/short_read/2017.12.04_18.45.54_sample_${SAMPLES[$PBS_ARRAYID]}/reads/anonymous_reads.fq.gz | samtools view -F 3584 -b --threads 8 > results/bam/${SAMPLES[$PBS_ARRAYID]}.bam

