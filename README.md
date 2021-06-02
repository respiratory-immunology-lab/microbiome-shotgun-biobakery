Using biobakery3 tools for metagenomics and metatranscriptomics sequencing
==========================================================================

This pipeline is based on [Biobakery](https://github.com/biobakery/biobakery) tools for shotgun metagenomics and metatranscriptomics profiling. This pipeline has been optimised to work on MASSIVE cluster for parallel processing of multiple samples.

## Biobakery tools installation on the cluster

MetaPhlAn (taxonomic profiling) and HUManN (functional profiling) will be installed along with KneadData (QC and host removal).

```bash
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

As of May 2021, this issue still persists. Therefore, use the following steps based on the link above. You will then use this new path as the location of Trimmomatic in section 1 (kneaddata steps).

```bash
# Navigate to a folder where you want to install Trimmomatic (e.g. ~/of33/share) - create folder if necessary (via mkdir function)
# The location for --trimmomatic in section 1 will in this case be: "/home/USERNAME/of33/share/Trimmomatic-0.33"
cd ~/of33/share

# Download the Trimmomatic .zip file and unzip it
curl -o Trimmomatic-0.33.zip http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.33.zip
unzip Trimmomatic-0.33.zip
```

## Installation of databases

The latest databases are **already downloaded** on the cluster and located under `of33/Databases/shotgun`. You might need to specifiy the full path when launching one of the pipelines.

```bash
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

The newer updates to the HUMAnN databases used in v3.0 may require a newer version of `diamond` than is automatically installed (hopefully this will be rectified in future updates). If you get an error message when running the code in section 2 below, then you can manually update your version of diamond using the code below.

```bash
# Download diamond v0.9.36
conda install -c bioconda diamond=0.9.36
```

## Running the pipeline 

The pipeline can be run using an interactive session or by wrapping everything up into bash scripts (provided [here](https://github.com/respiratory-immunology-lab/microbiome-shotgun-biobakery/edit/main/README.md)). Samples are processed in parallel using `gnu parallel` tool.

```bash
# Launch an interactive session
smux n --mem 200G --ntasks=36 --time=3-00:00:00 -J Humann_interactive

# OR RECOMMENDED
sbatch [script].sh

# Activate biobakery environment
source activate biobakery3

# Load gnu parallel
module load gnuparallel
```

### 1) Quality filtering and host genetic material removal

This is done using [KneadData](http://huttenhower.sph.harvard.edu/kneaddata) tool. Quality filtering includes trimming of 1) low-quality bases (default: 4-mer windows with mean Phred quality <20), 2) truncated reads (default: <50% of pre-trimmed length), and 3) adapter and barcode contaminants using `trimmomatic`. Depletion of host-derived sequences is performed by mapping with `bowtie2` against an expanded human reference genome (including known “decoy” and contaminant sequences) and optionally other hosts reference genomes and/or transcriptomes. Depletion of microbial ribosomal and structural RNAs by mapping against SILVA is also performed for metatranscriptomics.

The start of the pipeline assumes you have raw, merged by sequencing lane, fastq files `[sample]_merged_R1.fastq.gz` and `[sample]_merged_R1.fastq.gz` in a directory called `rawfastq`. See [here](https://github.com/respiratory-immunology-lab/microbiome-shotgun/blob/master/fastq_wrapper.sh) for a wrapper script that includes downloading data from BaseSpace and concatenating files from different lanes.

If your files are on Google Drive, you can view the `README.md` file in the `transfer_files` folder above for instructions on using `rclone` to transfer your files over to the cluster.

If you only have data from a single lane, then you are not required to merge files, and will therefore not have renamed files ending in `_merged_R1.fastq.gz`. 
In this case, for the first `for` loop (run kneaddata in parallel), change instances of `_R1` and `_R2` to `_R1_001` and `_R2_001` respectively; you do not need to change `_R` during `Basename` assignment however.
For the second `for` loop (extract human and non-human reads numbers from log files), in the `Basename` assignment, change `_merged` to `_R1_001`. Then, for the assignment of the `Microbial` variable, replace `R1` with `R1_001`.

```bash
# Create output directory
mkdir kneaddata_output

# Run KneadData in parallel
for f in rawfastq/*_R1.fastq.gz
do
  Basename=${f%_R*}
  echo kneaddata -t 6 -p 6 --input ${Basename}_R1.fastq.gz --input ${Basename}_R2.fastq.gz \
  --remove-intermediate-output --bypass-trf --output kneaddata_output \
  --trimmomatic /home/cpat0003/miniconda3/envs/biobakery3/bin/Trimmomatic-0.33 \
  -db /home/cpat0003/of33/Databases/shotgun/host/human/hg37dec_v0.1
done | parallel -j 4

# Remove contaminant files to increase space
rm -rf *contam*	

# Extract human and non human reads numbers from log files
for f in kneaddata_output/*.log
do
  Basename=${f%_merged*}
  Samplename=${Basename#*/}
  Human=$(sed -n 's/hg37dec_v0.1_bowtie2_paired_contam_1.fastq\(.*\).0/\1/p' $f | sed 's/.*: //')
  Microbial=$(sed -n 's/R1_kneaddata_paired_1.fastq\(.*\).0/\1/p' $f | sed 's/.*: //')
  echo $Samplename $Human $Microbial
done > read_counts.txt
```

Note: `-j 4` is for processing 4 samples at a time. It is possible to increase it but it takes up an enormous amout of space. Files from contaminant genome can be deleted by running `rm -rf *contam*`.

Although KneadData does use end-pairing information (e.g. for mapping against the host's genome), downstream tools (MetaPhlAn and HUMAnN) do not so we concatenate R1 and R2 (non-overlapping) into a single input file.

```bash
# Merge R1 and R2 reads 
for f in kneaddata_output/*_kneaddata_paired_1.fastq
do
  Basename=${f%_merged*}
  echo "ls ${Basename}*_kneaddata_paired* | xargs cat > ${Basename}_R1R2.fastq"
done | parallel -j 36
```

If you are processing data from a single lane, the corresponding merge can be achieved as follows, by replacing the `f%_merged*` with `f%_R1_001`.

```bash
# Merge R1 and R2 reads
for f in kneaddata_output/*_kneaddata_paired_1.fastq
do
  Basename=${f%_R1_001*}
  echo "ls ${Basename}*_kneaddata_paired* | xargs cat > ${Basename}_R1R2.fastq"
done | parallel -j 36
```

### 2) Run MetaPhlAn and HUMAnN (version 3)

HUMAnN is a pipeline for efficiently and accurately profiling the presence/absence and abundance of microbial pathways in a community from metagenomic or metatranscriptomic sequencing data given a reference database. It automatically runs MetaPhlAn tool for profiling the composition of microbial communities from metagenomic shotgun sequencing data. MetaPhlAn relies on unique clade-specific marker genes identified from ~17,000 reference genomes (~13,500 bacterial and archaeal, ~3,500 viral, and ~110 eukaryotic).

```bash
# Create output directories
mkdir humann_output

# Run MetaPhlAn and HUMAnN
for f in kneaddata_output/*_R1R2.fastq
do
  Basename=${f%_R*}
  Samplename=${Basename#*/}
  echo humann -v --input ${Basename}_R1R2.fastq --threads 6 \
  --bowtie-options "'-p 6 --very-sensitive-local'" \
  --nucleotide-database /projects/of33/Databases/shotgun/chocophlan \
  --protein-database /projects/of33/Databases/shotgun/uniref \
  --output humann_output/${Samplename} \
  --metaphlan-options "'--add_viruses --bt2_ps very-sensitive-local --min_alignment_len 100'"
done | parallel -j 6
```

#### Error: most reads remain unknown and unassigned

You may encounter an error where no bacteria are being assigned in your `metaphlan_bugs_list.tsv` file (located in the `_temp` folder within the sample output folder in `humann_output`). 
If this is the case, you may need to manually download and direct `humann` to the correct database for `metaphlan` analysis.
You can do this as follows:

```bash
# Create a folder to store the MetaPhlAn database (it doesn't matter where)
mkdir metaphlan_db
cd metaphlan_db

# Install the database within this folder
metaphlan --install --index mpa_v30_CHOCOPhlAn_201901 --bowtie2db .
```

Then, in the call to humann, under the `--metaphlan-options` flag, add the `--bowtie2db` flag and direct MetaPhlAn to the correct database to use.

```bash
# Run MetaPhlAn and HUMAnN
for f in kneaddata_output/*_R1R2.fastq
do
Basename=${f%_R*}
  Samplename=${Basename#*/}
  echo humann -v --input ${Basename}_R1R2.fastq --threads 6 \
  --bowtie-options "'-p 6'" \
  --nucleotide-database /projects/of33/Databases/shotgun/chocophlan \
  --protein-database /projects/of33/Databases/shotgun/uniref \
  --output humann_output/${Samplename} \
  --metaphlan-options "'--bowtie2db path/to/metaphlan_db --min_alignment_len 100'"
done | parallel -j 6
```

### 3) Merge output tables

```bash
# Merge metaphlan tables
find humann_output -name "*bugs_list.tsv" | xargs merge_metaphlan_tables.py -o metaphlan_all_samples.tsv

# Merge humann tables
humann_join_tables -i humann_output -s -o pathcoverage_all_samples.tsv --file_name pathcoverage
humann_join_tables -i humann_output -s -o pathabundance_all_samples.tsv --file_name pathabundance
humann_join_tables -i humann_output -s -o genefamilies_all_samples.tsv --file_name genefamilies

# Add names to Uniref IDs
humann_rename_table -i genefamilies_all_samples.tsv -c ~/of33/Databases/shotgun/utility_mapping/map_uniref90_name.txt -o genefamilies_all_samples_uniref_names.tsv

# Split tables into stratified and unstratified
humann_split_stratified_table -i genefamilies_all_samples_uniref_names.tsv -o .
humann_split_stratified_table -i pathabundance_all_samples.tsv -o .
humann_split_stratified_table -i pathcoverage_all_samples.tsv -o .
```

Optional: Map the uniref90 IDs to KEGG or GO IDs.

```bash
# Regroup into KEGG IDs and add names
humann_regroup_table -i genefamilies_all_samples.tsv --output genefamilies_all_samples_KO.tsv -c ~/of33/Databases/shotgun/utility_mapping/map_ko_uniref90.txt
humann_rename_table -i genefamilies_all_samples_KO.tsv -c ~/of33/Databases/shotgun/utility_mapping/map_ko_name.txt -o genefamilies_all_samples_KO_names.tsv

# Regroup into GO IDs and add names
humann_regroup_table -i genefamilies_all_samples.tsv --output genefamilies_all_samples_GO.tsv -c ~/of33/Databases/shotgun/utility_mapping/map_go_uniref90.txt
humann_rename_table -i genefamilies_all_samples_GO.tsv -c ~/of33/Databases/shotgun/utility_mapping/map_go_name.txt -o genefamilies_all_samples_GO_names.tsv
```

Optional: Perform normalisation (can also be done downstream in R).

```bash
# Normalise gene families and pathways abundances and ignore special features UNMAPPED, UNINTEGRATED, and UNGROUPED
humann_renorm_table -i genefamilies_all_samples.tsv -o genefamilies_all_samples_uniref_CoPM.tsv -s n --units cpm
```

## Citation

If you used this repository in a publication, please mention its url.

In addition, you may cite the tools used by this pipeline:

* **bioBakery:** McIver LJ, Abu-Ali G, Franzosa EA, Schwager R, Morgan XC, Waldron L, Segata N, Huttenhower C. bioBakery: a meta'omic analysis environment. Bioinformatics. 2018 Apr 1;34(7):1235-1237. PMID: 29194469.

## Rights

* Copyright (c) 2021 Respiratory Immunology lab, Monash University, Melbourne, Australia.
* License: This pipeline is provided under the MIT license (See LICENSE.txt for details)
* Authors: C. Pattaroni
