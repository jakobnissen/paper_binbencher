mkdir -p tmp/renamed_amber;
mkdir -p results/unsplit_samplewise;
for i in 0 1 2 3 4 5 9 10 11 12; do
    cat raw/gi_${i}.bins | sed -E 's/@SampleID:[0-9]+/@SampleID:all/' > tmp/renamed_amber/${i}.bins
    amber.py -g tmp/renamed_amber/${i}.bins -o results/unsplit_samplewise/${i} results/bbformat/unsplit.binning
done;
