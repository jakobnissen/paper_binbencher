#set par(justify: true, leading: 0.5em)
#set text(font: "New Computer Modern", size: 10pt)
#set page(
  paper: "a4",
  margin: (x: 1.6cm, y: 2cm),
  header: align(right + horizon, "BinBencher preprint")
)
#set heading(numbering: "1.")
#set page(numbering: "1 / 1")

#align(center, text(17pt)[*BinBencher: Fast, flexible and meaningful benchmarking suite for metagenomic binning*])

#grid(
  columns: (1fr, 1fr, 1fr),
  align(center)[
    Jakob Nybo $"Nissen"^1*$ \
    #link("mailto:jakob.nissen@sund.ku.dk")
  ],
  align(center)[
    Pau Piera $"Lindéz"^1$ \
    #link("mailto:pau.piera@sund.ku.dk")
  ],
  align(center)[
    Simon $"Rasmussen"^1*$ \
    #link("mailto:simon.rasmussen@sund.ku.dk")
  ]
)

#align(center)[
  #set par(justify: false)
  #set text(font: "New Computer Modern", size: 8pt)
  1: Novo Nordisk Foundation Center for Basic Metabolic Research, Faculty of Health and Medical Sciences, University of Copenhagen, Denmark
  \* Corresponding author
]

#align(center)[
  #set par(justify: true)
  *Abstract* \
New methods for metagenomic binning are typically evaluated using benchmarking software, and become tuned to maximize whatever criterion is measured by the benchmark. Subtleties in benchmarking procedures can cause misleading evaluations, derailing method development. Differences between procedures used to evaluate binning tools make them hard to compare, which slows progress in the field.
We introduce BinBencher, a free software suite for benchmarking, and show how BinBencher produces evaluations that are more biologically meaningful than alternative benchmarking approaches.
]

#v(25pt)
#show: rest => columns(2, rest)

= Introduction
In the last decade, the number of known microbial species have exploded, largely due to culture-independent methods of discovery, where genomes are reconstructed from nucleotide sequences obtained directly from environmental samples, as done in e.g. @almeida_new_2019 and @parks_recovery_2017.
// Consider semantic line breaks https://sembr.org
// (I've got some code I can run to do it, but the diff would be massive, so i won't do it without your say-so)
In a typical workflow, reads from an environmental sample are _de novo_ assembled to contigs. 
Even when using the latest metagenomic assemblers with long, accurate reads, genomes are often incompletely assembled, and may be fragmented in several contigs @feng_evaluating_2024 @benoit_high-quality_2024.
To reconstruct the original genomes, the contigs can be grouped by their genome of origin, in a process called 'binning'.

Programs used for binning, or 'binners', typically rely on sequence features which correlate probabilistically between sequences of the same genome, such as k-mer composition and co-abundance.
Therefore, binning is an error-prone process, where most output bins usually do not accurately correspond to genomes, but have some degree of incompleteness or contamination.
In attempts to improve binning accuracy, there have been many papers published in recent years presenting new techniques. We know of at least 19 binners published the last decade, not including updates to existing binners @wu_maxbin_2014 @alneberg_binning_2014 @imelfort_groopm_2014 @kang_metabat_2015 @lin_accurate_2016 @graham_binsanity_2017 @lu_cocacola_2017 @yu_bmc3c_2018 @uritskiy_metawrapflexible_2018 @sieber_recovery_2018 @demaere_bin3c_2019 @wang_solidbin_2019 @nissen_improved_2021 @liu_metadecoder_2022 @pan_deep_2022 @wang_metabinner_2023 @zhang_graph-based_2023 @wang_effective_2024 @lettich_genomeface_2024 @feng_evaluating_2024.

Typically, the accuracy of a binner is measured by running the binner on a dataset with a known ground truth reference, usually an _in silico_ simulated metagenome or an artificially produced mock community, and comparing the output bins against the reference, as done in e.g. @kang_metabat_2015 @lin_accurate_2016 @wang_solidbin_2019 @nissen_improved_2021 @liu_metadecoder_2022 @pan_deep_2022  @wang_effective_2024  @lettich_genomeface_2024.
An alternative approach is to directly evaluate the bins, in the absence of a ground truth reference, using statistical models.
Most commonly used is CheckM@parks_checkm:_2015 and its newer version CheckM2@chklovski_checkm2_2023.
These programs cannot fully replace simulated microbiomes for several reasons:
First, they are themselves calibrated using simulated data.
Second, as statistical models, they are not entirely accurate and may mispredict the accuracy of a bin.
Third, in the case of CheckM2, its use of machine learning makes its results less explainable than ground-truth based benchmarking, making it less useful as a guide to develop new binning techniques.

In most recent papers presenting new binners, the authors claim superior binning accuracy over their competitors in benchmarks - claims, which often conflict with those made in other papers.
For example, the authors of MetaBAT showed it was more accurate than MaxBin@kang_metabat_2015, whereas @lin_accurate_2016 showed that MetaBAT was better on one dataset, but worse on another. In @wang_solidbin_2019 and @graham_binsanity_2017, however, MaxBin beat MetaBAT.
Comparing the respective upgrades, MetaBAT2 to MaxBin2, the former was the better choice according to @nissen_improved_2021 @liu_metadecoder_2022 @pan_deep_2022, but they perform about equally well in @wang_effective_2024, and MaxBin2 won in @zhang_graph-based_2023.
Similarly, MetaBAT2 was _much_ better than VAMB according to @liu_metadecoder_2022, and somewhat better in @zhang_graph-based_2023, but only on par in @wang_effective_2024. In contrast, @pan_deep_2022 found VAMB to beat MetaBAT2 and, unsurprisingly, so did we in the original VAMB paper @nissen_improved_2021.

This status quo is bad for users, who can't easily tell which binners really are the best to use, and who rarely have the time to undergo a detailed, systematic study of the many available binners.
It's also bad for tool developers, because the conflicting claims of accuracy makes it difficult to know which techniques are promising to develop further, and even to know whether the field is making progress in the sense that binners are getting more accurate over time.

Binning is not unique in being a well-studied computational problem with a proliferation of candidate evaluation techniques - parallels can be drawn to the protein folding problem and the problem of computer vision.
Both fields have benefitted greatly from standardized evaluations provided by e.g. CASP@moult_large-scale_1995 and ImageNet@deng_imagenet_2009, respectively.
In the field of binning, the Critical Assessment of Metagenome Interpretation (CAMI)@sczyrba_critical_2017 and CAMI2@meyer_critical_2022 is a similar initiative that aims to standardize benchmarking of various metagenomic tools, including binners. To this end, they have developed the binning benchmarking tool AMBER@meyer_amber_2018.

In this paper, we will demonstrate how subtle differences in the benchmarking procedure have profound impact on the assessment of bins. We show how seemlingly straightforward procedures, including that used by AMBER, can result in misleading scores. We present BinBencher, a benchmarking suite for binnings of simulated metagenomes which produce more biologically meaningful results.

= Results
== BinBencher can selectively include or disregard microdiversity
Creators of synthetic datasets may include distinct genomes that are highly similar in order to test how binners handle microdiversity. For example, the GI dataset (see Methods) contains sequences from 98 species that have more than one genome in the dataset. Of these, 33 species have a mean pairwise average nucleotide identity (ANI) between its genomes above 99%, and 12 above 99.9%, according to FastANI v1.34 @jain_high_2018 (@ani). In total, there are 3,371 genome pairs with an ANI $gt.eq$ 99%, and 1,903 pairs $gt.eq$ 99.9%.
// I assumed this is what you meant. If so, note you can also just do >= for these

#figure(
  image("ani.svg", width: 100%), // None of these figures appear to be committed. I added blank svgs to be able to compile
  caption: [
    #set text(font: "New Computer Modern", size: 8pt)
    Mean average nucleotide identity (ANI) within each multi-genome species in the GI dataset. For every species with more than one genome, the mean ANI was computed across all genome-genome pairs in that species.
    The high level of ANI implies that computing precision at genome level can result in intra-bin microdiversity being classified as contamination despite being > 99% identical on the nucleotide level.
]
) <ani>

In this paper, we operationally define 'microdiversity' to be a collection of sequences from different genomes with an ANI of $eq.gt$ 99%.
Depending on the objective of the researcher performing the benchmark, microdiversity may not be considered contamination at all, but rather natural variation within a single genome. CheckM, for example, reports the fraction of contamination that results from sequences with an amino acid identity $eq.gt$ 90% as 'strain heterogeneity'@parks_checkm:_2015.
Given that short-read assemblers struggle with preserving diversity at a >96% level @vollmers_comparing_2017, and the popular assembler metaSPAdes even explicitly aims to assemble the consensus of mixed strains @nurk_metaspades:_2017 and thus co-assembles similar strains, we found it unlikely that researchers with short-read data will have microdiversity correctly preserved in the contigs input to binning.

When computing bin precision relative to a genome, sequences from any other genome count as equally contaminating, no matter if they are from a remotely related organism, or are microdiversity.
If the researcher does not want to distinguish microdiversity, the bin precision can therefore be significantly underestimated.
However, if the research objective is to correctly separate microdiversity to resolved strains, then microdiversity in a bin ought to be considered contamination.

BinBencher addresses these conflicting requirements in two ways:
First, BinBencher allows contigs to map to any number of underlying genomes, and therefore works correctly when given bins containing contigs from a consensus assembly of different genomes. Second, BinBencher benchmarks on multiple taxonomic ranks simultaneously (see Methods). Thus, the user may define a taxonomic rank that groups highly similar genomes in their dataset, and when benchmarking, the user can choose between BinBencher's metrics at the genome level, or at this higher taxonomic rank.

To illustrate this, of the 109 bins of the GI dataset with recall $eq.gt$ 0.9 and nonzero contamination, 31 had zero contamination when disregarding microdiversity. However, when benchmarking on the taxonomic level of species, none of the reported contamination from any of the 68 contaminated bins with recall $eq.gt$ // not changing all of these, in case I'm wrong
0.9 was due to microdiversity (@precision), because genomes from different bacterial species usually differ by more than 5% ANI@jain_high_2018.

#figure(
  image("precision.svg", width: 100%),
  caption: [
    #set text(font: "New Computer Modern", size: 8pt)
    The fraction of contamination that is due to microdiversity, i.e. contamination from genomes $eq.gt$ 0.99 ANI to the main genome in the bin. Only bins with recall $eq.gt$ 0.9 and nonzero contamination are included. Top: Recall/precision is computed on the genome level, bottom: on the species level. The bottom plot contains less data because fewer bins have nonzero contamination on the species level. By choosing the taxonomic rank of benchmarking, users can selective choose to include or disregard microdiversity.
   ]
) <precision>

== BinBencher avoids common pitfalls when evaluating multi-sample binnings
When benchmarking binnings, the same genome may be present in multiple samples.
In the common 'multi-split' binning workflow, reads from each sample are assembled independently, contigs from all samples are binned together, and then the resulting bins are split by their sample to sample-wise pure bins.
This workflow allows co-abundance to be leveraged across samples more effectively by the binner, while also resulting in bins that, because they originate from only a single sample, do not mix different strains occurring in different samples.
It has been shown previously@nissen_improved_2021 @mattock_comparison_2023 that multi-splitting produces more accurate bins than binning samples independently and pooling the result.

When benchmarking multi-sample binnings, the user may choose to benchmark once per sample against a sample-specific reference, or once against a single cross-sample reference. Further, the user may benchmark the output of the binner including sequences from all samples, or subset the bins by sample. These two dilemmas leads to a total of four options when benchmarking.
As we will show, three of these four possibilities introduce bias when using benchmarking frameworks that compute accuracy based on the number of basepairs present in the bins relative to the reference, such as AMBER.

=== Cross-sample references cause missing sequences to count against recall, even if they are redundant
If the user benchmarks against a cross-sample reference, then recall will be underestimated by AMBER. Suppose a 3 Mbp genome is present in five samples. To reach a recall of 1, a bin must have all $3 * 5 = 15$ Mbp present. A bin with a full 3 Mbp copy of the genome will have a reported recall of 0.2, despite the missing 12 Mbp being fully redundant, as it maps to the same genomic positions as the extant 3 Mbp.

In the GI dataset, of the 172 bins $eq.gt$ 200 kbp with AMBER recall < 1, for 101 of them, more than half of the genomic content reported as missing by AMBER was redundant. 34 of them fully recovered the genome, i.e. all missing content was redundant (@redundant, top).
This problem was exacerbated in the multi-split workflow, because no output bins contained sequences from multiple samples, and so for 253 of the 294 incomplete bins, more than half their missing content was redundant, and for 52 of them, all missing content was redundant. (@redundant, bottom).

#figure(
  image("redundant.svg", width: 100%),
  caption: [
    #set text(font: "New Computer Modern", size: 8pt)
    A bin's missing basepairs (bp) is the number of bp needed for that bin to reach a recall=1 according to AMBER. We consider missing bp to be redundant if they map to the same genomic positions as bp already in the bin. Top: Most bins $eq.gt$ 200 kbp are reported to be incomplete by AMBER, but most of the missing bp in these incomplete bins are redundant. Bottom: This effect is even more pronounced for bins from the multi-split binning workflow.
  ]
) <redundant>

Because BinBencher computes recall in terms of genomic positions, redundant sequences are never included in the recall computation, and this issue does not occur.

=== Sample-specific references cause miscomputed precision and recall for cross-sample binnings
If the user benchmarks against sample-specific references using AMBER, they must take care to split the binning by sample.
Any sequences from a different sample are missing from the reference and will be ignored, leading to incorrectly computed recall and precision.

To quantify the error, we compared recall and precision reported by AMBER for cross-sample binnings using single-sample references to the values when using a cross-sample reference with all sequences present. For 58 of the 203 bins $eq.gt$ 200 kbp, the recall error was $eq.gt$ 0.1, and for 39, it was $eq.gt$ 0.5. For precision, the values were 86 of 203 and 34 of 203, respectively (@errors).

#figure(
  image("errors.svg", width: 100%),
  caption: [
    #set text(font: "New Computer Modern", size: 8pt)
    Benchmarking a multi-sample binning with a single-sample reference causes miscomputed precision and recall in AMBER due to sequences missing from the reference.
    The error reported here is the reported value minus the value when all sequences are present in the reference, for bins $eq.gt$ 200 kbp in size.
]
) <errors>

While using AMBER with cross-sample binnings and single-sample references is a user error, it is an easy mistake to make.
BinBencher will reject any binnings containing sequences not present in the reference, making this error impossible.

== BinBencher accurately computes recall for poorly assembled genomes
When computing the recall of a genome/bin pair, it could be computed relative to the genome size ('genomic recall'), or relative to the portion of the genome covered by any sequence input in the binner, typically the assembled part of the genome ('asm recall').
Genomic and asm recall differ for genomes that are not wholly assembled and each may be the most useful metric depending on the objective.
Let us define "recall gap" to be asm recall minus genomic recall.

The GI dataset is assembled with the CAMI 'gold standard assembler', a perfect ground-truth guided assembler, producing far higher quality contigs than what is realistically achievable using its input data@sczyrba_critical_2017, hence the recall gap for this dataset is small (@unasm, left).
To investigate the recall gap for more realistic data, we created a new ground truth reference by assembling the GI reads with the metaSPAdes assembler and binning the results (see Methods).
For this dataset, 169 bins have a recall gap of $eq.gt$ 0.1, and of the 49 bins with an asm recall of $eq.gt$ 0.9, 22 had a genomic recall of < 0.5 (@unasm, right).

Targeting asm recall when evaluating binning risks incentivizing underclustering, since small clusters are less likely to be contaminated, while still being able to encompass the assembled parts of genomes where only a few short sequences could be assembled.
For example, in our experiment, bin 3993 had an asm recall of 1, because it consisted of the sole 4 kbp contig that was assembled from the bacterium _Taylorella equigenitalis_.
Hence, the precision/recall tradeoff of a binner may be evaluated differently when assessing the number of high quality bins, depending on whether genomic or asm recall is used.

In our view, genomic recall aligns more closely to the common research objective of reconstructing whole and pure genomes. With this objective, asm recall can be misleading - a researcher might find a bin is assigned to some genome with a high recall, not realizing that this does not necessarily means the genome is recovered.
On the other hand, since no binner can produce bins containing sequences that were not input to the program, asm recall has the useful property that the maximally achievable recall by any bin is 1, independent of how well the genome is assembled.

Because only reporting asm recall for poorly assembled bins can be misleading, BinBencher computes all statistics from both asm and genomic recall, but reports only those derived from the more biologically relevant genomic recall, unless explicitly requested.

#figure(
  image("unasm_recall.svg", width: 100%),
  caption: [
    #set text(font: "New Computer Modern", size: 8pt)
    Recall relative to the assembled part of the genome ('asm recall'), versus recall relative to the full genome ('genomic recall'). Left: The GI gold standard assembly shows little difference between the two recall measures due to its unrealistically high quality. Right: A more realistic assembly using metaSPAdes reveals how genomic and asm recall may differ significantly for some bin/genome pairs.
  ]
) <unasm>

== Runtime and memory usage
To measure runtime and memory usage, we timed benchmarking all samples in the multi-split workflow.
BinBencher ran faster than AMBER, taking 3 versus 180 CPU seconds, respectively.
However, AMBER consumed only 267 MB memory compared to the 688 used to BinBencher.

#figure(
  table(
    columns: (1fr, auto, auto),
    inset: 2pt,
    align: horizon,
    [*Tool*], [*CPU time (s)*], [*Memory (MB)*],
    [BinBencher], [*3*], [688],
    [AMBER], [180], [*267*],
    //[CheckM2], [43747], [16514],
  ),
  caption: [CPU and memory usage of binning benchmark tools]
) <runtime>

#colbreak()
= Discussion
Evaluation is a necessary part of tool development. The chosen method of evaluation ultimately decides if a new tool, or a new development to an existing tool, is considered an improvement.
As we have shown in this paper, evaluating metagenomic binnings is not trivial, even with a ground-truth based reference available, but presents multiple pitfalls that can cause wrong or misleading evaluations.
We believe these misleading evaluations can derail tool development.
Indeed, during the development of our own binner, VAMB, we chased several promising techniques that turned out to only appear promising because of benchmarking artifacts.
This experience made us invest significant amount of time in developing correct benchmarking techniques, eventually leading to the creation of BinBencher.
We hope that the publication of BinBencher will enable other developers of binners to spend less time worrying about benchmarking, while also providing them with a more accurate metric to target.

Unfortunately, binning evaluation remains somewhat subjective.
For example, there is no objective answer to how phylogenically precise a bin must be to be considered pure, nor an objective tradeoff between precision and recall.
BinBencher strives to provide defaults that are generally biologically meaningful, and compute multiple metrics where there is no objectively right answer.

Nonetheless, BinBencher is still lacking in some important respects:
- BinBencher's default measure, the number of recovered high-quality genomes, does not penalize the existence of additional poor quality bins.
  However, BinBencher provide several additional metrics.
- BinBencher provides no option for handling chimeric contigs that ought to be split apart in multiple bins. This is because every sequence input to BinBencher must be present in the reference. However, we note that none of the binners we know about are able to detect and split chimeric contigs.

= Methods
== Computation of the default metric reported by BinBencher
BinBencher computes a variety of statistics, but the default reported metric is _number of recovered high-quality genomes_, which we define below.

The ground truth contains a number of genomes $G$ that can be considered disjoint sets of genomic positions. $Y$ is the set of all mapping positions, i.e. $Y = union_G$.
Let $X$ be a set of sequences $S$ to be binned.
Each sequence $S$ has length $L_S$, and can be considered as a set of mapping positions $S subset.eq Y$, and its cardinality $|S|$ may be larger, equal to, or smaller than $L_S$.
If we have a set of sequences $x subset.eq X$ and a set of mapping positions $y subset.eq Y$, let us define $x sect.double y colon.eq {S in x | S sect y eq.not emptyset}$, the subset of $x$ with sequences mapping to $y$.

A bin $B$ is a set of sequences $B subset.eq X$.
For any bin/genome pair ${B, G}$, we have:
- $"TP"_"{B,G}" = |union_(S in B)S sect G|$, is the true positives, the number of positions in $G$ that any sequence in $B$ is mapped to.
- $"FP"_"{B,G}" = sum_(S in B without (B sect.double G))L_S$ is the false positives, the sum of lengths of sequences in $B$ that does not map to $G$.
- $"FN"_{B,G} = |G| - "TP"_{B,G}$, the false negatives, are all positions in $G$ not covered by any sequence in $B$.

From these definitions we define recall $R_{B,G}$ and precision $P_{B,G}$ the usual way.
We can then count the number of recovered genomes at recall/precision thresholds $T_R, T_P$ as
$Q_{T_R, T_P} = $
$ |{G | P_{B,G} eq.gt T_P and "R"_{B,G} eq.gt T_R "for any" B}| $
The default thresholds are $T_R = 0.9, T_P = 0.95$.

There are several differences between BinBencher's and AMBER's computed measures, but the most important is that AMBER uses $"TP"_{B,G} = sum_(S in B sect.double G) L_S$ and $"FN"_{B,G} = sum_((X sect.double G) without B) L_S$, i.e. it counts the sum of the lengths of sequences instead of unique mapping positions.

== Benchmarking on multiple phylogenetic ranks
In BinBencher reference files, every genome is organized in a phylogenetic tree.
Genomes are the lowest taxonomic rank in the tree, assigned rank zero.
Every member of taxonomic rank $T$ has a parent of rank $T + 1$, except the final taxonomic rank which has no parent and only one member, the ancestor of every genome in the reference.

BinBencher computes precision/recall for every ${B,C_T}$ pair of bin with a clade of rank $T$.
The values of ${B,C_0}$ are bin-genome pairs, and their precision and recall are computed as shown in the previous section.
We denote the set of direct children of clade $C_T$ to be $H(C_T)$.
For the non-genomes clades $C_T$ where $T > 0$, we have
$P_{B,C_T} = sum_(C_(T-1) in H(C_T))P_{B,C_(T-1)}$ and
$R_{B,C_T} = max_(C_(T-1) in H(C_T))R_{B,C_(T-1)}$.

== Dataset and software used
For the results presented in this paper, we used the 10 synthetic Gastrointestinal short-read samples from the 2nd CAMI Toy Human Microbiome Project Dataset (the "GI" dataset)@meyer_critical_2022.
We ran VAMB v4.1.3 to produce the bins measured in this manuscript, and benchmarked the output using BinBencher v0.3.0 and AMBER v2.0.4

== Reassembling and binning the GI dataset
To assemble the GI dataset, we ran SPAdes v. 3.15.5 with the `--meta` option@nurk_metaspades:_2017 and default parameters on reads from each sample.
We then concatenated output contigs of length $eq.gt$ 2 kbp to a single file used as input to binning.
To get a reference, we aligned contigs from each sample against the underlying genomes which had a nonzero abundance in that sample using BLAST v2.15.0 @camacho_blast_2009, and accepted all hits with the arbitrary cutoffs $eq.gt$ 95% identity and $eq.gt$ 90% query coverage.
The re-assembled contigs were binned with VAMB v4.1.3 using default parameters.

== Code availability
The code used to produce this paper can be found at https://github.com/jakobnissen/paper_binbencher. BinBencher itself is freely available at https://github.com/jakobnissen/BinBencher.jl.

== Data availability
The GI dataset is made available by the Critical Assessment for Metagenome Evaluation, at https://frl.publisso.de/data/frl:6425518. 

== Acknowledgements
This work is supported by the Novo Nordisk Foundation (NNF20OC0062223 and NNF23SA0084103).

== Conflicts of interest
The authors are the author of the VAMB binning tool, which has been developed using a prototype of BinBencher, and therefore appears to perform better when evaluated using the techniques we advocate for in this paper. Additionally, SR is the founder and owner of BioAI and have performed consulting for Sidera Bio ApS.

#bibliography("binbench.bib")

/*
#pagebreak()

#set text(font: "New Computer Modern", size: 10pt)
#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2cm),
  header: align(right + horizon, "BinBencher df")
)
#counter(heading).update(0)
#align(center, text(17pt)[*BinBencher suplementary information*])
= Table of published binning tools
*/
