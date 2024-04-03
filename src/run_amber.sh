#amber.py -g raw/ref_gi.bins -o results/amber_all_split results/bbformat/split.binning
#amber.py -g raw/ref_gi.bins -o results/amber_all_unsplit results/bbformat/unsplit.binning
for i in 1 2 3 4 5 9 10 11 12; do amber.py -g raw/gi_${i}.bins -o results/amber_${i} results/bbformat/s${i}.binning; done
