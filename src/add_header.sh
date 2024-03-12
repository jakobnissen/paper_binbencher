echo -e "clustername\tcontigname" > results/vambout/unsplit_header.tsv
cat results/vambout/vae_clusters.tsv >> results/vambout/unsplit_header.tsv
echo -e "clustername\tcontigname" > results/vambout/split_header.tsv
cat results/vambout/vae_clusters_split.tsv >> results/vambout/split_header.tsv
