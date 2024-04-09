module load tools;
module load vamb/4.1.3;
vamb --outdir results/vambout_asm --fasta results/spades/catalogue.fna --bamfiles results/bam/*.sorted.bam -p 10
