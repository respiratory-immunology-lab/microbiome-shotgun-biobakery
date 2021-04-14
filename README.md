Using biobakery3 tools for metagenomics and metatranscriptomics sequencing
==========================================================================

This pipeline is based on [Biobakery](https://github.com/biobakery/biobakery) tools for shotgun metagenomics and metatranscriptomics profiling. This pipeline has been optimised to work on MASSIVE cluster for parallel processing of multiple samples.

## Biobakery tools installation on the cluster

MetaPhlAn (taxonomic profiling) and HUManN (functional profiling) will be installed along with KneadData (QC and host removal).

```
# Create a conda environment
conda create --name biobakery3 python=3.7

# Activate environment
conda activate biobakery3

# Set specific channels
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --add channels biobakery

# Install HUMAnN3 and MetaPhlAn3 (MetaPhlAn automatically comes with HUMAnN)
conda install humann -c biobakery

# Install kneaddata
pip install kneaddata
```
If there is an issue with `trimmomatic` error message, check this issue: https://github.com/bioconda/bioconda-recipes/issues/18666 and re-install binaries.

## Installation of databases

The latest databases are **already downloaded** on the cluster and located under `of33/Databases/shotgun`. You might need to specifiy the full path when launching one of the pipelines.

```
# Download pangenome database
humann_databases --download chocophlan full /path/to/databases --update-config yes --index latest

# Download protein database
humann_databases --download uniref uniref90_diamond /path/to/databases --update-config yes

# Download annotations database
humann_databases --download utility_mapping full /path/to/databases --update-config yes

# Download human genome (DNAseq)
kneaddata_database --download human_genome bowtie2 /path/to/databases

# Download human transcriptome (RNAseq)
kneaddata_database --download human_transcriptome bowtie2 /path/to/databases

# Download SILVA database (RNAseq)
kneaddata_database --download ribosomal_RNA bowtie2 path/to/databases
```

## Running the pipeline 

The pipeline can be run using an interactive session (recommended) or by wrapping everything up into a bash script. Samples are processed in parallel using `gnu parallel` tool.

```
# Launch an interactive session
smux n --mem 300G --ntasks=6 --cpuspertask=6 --time=3-00:00:00 -J Humann_interactive

# Activate biobakery environment
source activate biobakery3

# Load gnu parallel
module load gnuparallel
```

### 1) Quality filtering and host genetic material removal

This is done using [KneadData](http://huttenhower.sph.harvard.edu/kneaddata) tool. Quality filtering includes trimming of 1) low-quality bases (default: 4-mer windows with mean Phred quality <20), 2) truncated reads (default: <50% of pre-trimmed length), and 3) adapter and barcode contaminants using `trimmomatic`. Depletion of host-derived sequences is performed by mapping with `bowtie2` against an expanded human reference genome (including known “decoy” and contaminant sequences) and optionally other hosts reference genomes and/or transcriptomes. Depletion of microbial ribosomal and structural RNAs by mapping against SILVA is also performed for metatranscriptomics.

The start of the pipeline assumes you have raw, merged by sequencing lane, fastq files `[sample]_merged_R1.fastq.gz` and `[sample]_merged_R1.fastq.gz` in a directory called `rawfastq`. See [here](https://github.com/respiratory-immunology-lab/microbiome-shotgun-biobakery) for a wrapper script that includes downloading data from BaseSpace and concatenating files from different lanes.

```
# Run KneadData in parallel
for f in rawfastq/*_R1.fastq.gz
do
  Basename=${f%_R*}
  echo kneaddata -t 6 -p 6 --input ${Basename}_R1.fastq.gz --input ${Basename}_R2.fastq.gz \
  --remove-intermediate-output --bypass-trf --output kneaddata_output \
  --trimmomatic /home/cpat0003/miniconda3/envs/biobakery3/bin/Trimmomatic-0.33 \
  -db /home/cpat0003/of33/Databases/shotgun/host/human/hg37dec_v0.1
done | parallel -j 4
```

Note: `-j 4` is for processing 4 samples at a time. It is possible to increase it but it takes up an enormous amout of space. Files from contaminant genome can be deleted by running `rm -rf *contam*`.

Although KneadData does use end-pairing information (e.g. for mapping against the host's genome), downstream tools (MetaPhlAn and HUMAnN) do not so we concatenate R1 and R2 (non-overlapping) into a single input file.

```
# Merge R1 and R2 reads 
for f in kneaddata_output/*_kneaddata_paired_1.fastq
do
  Basename=${f%_merged*}
  echo "ls ${Basename}*_kneaddata_paired* | xargs cat > ${Basename}_R1R2.fastq"
done | parallel -j 36
```

### 2) Run MetaPhlAn and HUMAnN (version 3)

HUMAnN is a pipeline for efficiently and accurately profiling the presence/absence and abundance of microbial pathways in a community from metagenomic or metatranscriptomic sequencing data given a reference database. It automatically runs MetaPhlAn tool for profiling the composition of microbial communities from metagenomic shotgun sequencing data. MetaPhlAn relies on unique clade-specific marker genes identified from ~17,000 reference genomes (~13,500 bacterial and archaeal, ~3,500 viral, and ~110 eukaryotic).

```
for f in kneaddata_output/*_R1R2.fastq
do
Basename=${f%_R*}
Samplename=${Basename#*/}
echo humann -v --input ${Basename}_R1R2.fastq \
--threads 6  --remove-temp-output --bowtie-options very-sensitive-local \
--nucleotide-database /projects/of33/Databases/shotgun/chocophlan \
--protein-database /projects/of33/Databases/shotgun/uniref \
--metaphlan-options "--stat_q 0.1 --no_map --bt2_ps very-sensitive-local \
--min_alignment_len 100 --add_viruses --nproc 6 \
-o metaphlan_output/${Samplename}_marker_abundance_table.txt" \
--output humann_output/${Samplename}
done | parallel -j 36
```

### 3) Merge output tables

### 1) 

### 1) 

### 1) 


## Citation

If you used this repository in a publication, please mention its url.

In addition, you may cite the tools used by this pipeline:

* **bioBakery:** McIver LJ, Abu-Ali G, Franzosa EA, Schwager R, Morgan XC, Waldron L, Segata N, Huttenhower C. bioBakery: a meta'omic analysis environment. Bioinformatics. 2018 Apr 1;34(7):1235-1237. PMID: 29194469.

## Rights

* Copyright (c) 2021 Respiratory Immunology lab, Monash University, Melbourne, Australia.
* License: This pipeline is provided under the MIT license (See LICENSE.txt for details)
* Authors: C. Pattaroni
