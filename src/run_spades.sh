module load tools;
module load anaconda3/2023.09-0;
module load spades/3.15.5;

SAMPLES=("0" "1" "2" "3" "4" "5" "9" "10" "11" "12");
mkdir -p results/spades;
spades.py --meta --12 /home/databases/bioinf_db/CAMI2/HUMAN/Gastrointestinal/short_read/2017.12.04_18.45.54_sample_${SAMPLES[$PBS_ARRAYID]}/reads/anonymous_reads.fq.gz -t 20 -m 90 -o results/spades/${SAMPLES[$PBS_ARRAYID]};
