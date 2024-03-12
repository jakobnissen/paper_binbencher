bbformat results/vambout/vae_clusters_split.tsv results/bbformat/split.binning
bbformat results/vambout/vae_clusters_unsplit.tsv results/bbformat/unsplit.binning
for i in 0 1 2 3 4 5 9 10 11 12; do echo -e "@Version:0.9.1\n@SampleID:${i}\n\n@@SEQUENCEID\tBINID\tTAXID" > results/bbformat/s${i}.binning && rg "^S${i}C" results/bbformat/split.binning >> results/bbformat/s${i}.binning; done
