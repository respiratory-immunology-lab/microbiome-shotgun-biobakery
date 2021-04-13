Using biobakery3 tools for metagenomics and metatranscriptomics sequencing
==========================================================================

This pipeline is based on [Biobakery](https://github.com/biobakery/biobakery) tools for shotgun metagenomics and metatranscriptomics profiling. This pipeline has been optimised to work on MASSIVE cluster.

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

### 1) 


## Citation

If you used this repository in a publication, please mention its url.

In addition, you may cite the tools used by this pipeline:

* **bioBakery:** McIver LJ, Abu-Ali G, Franzosa EA, Schwager R, Morgan XC, Waldron L, Segata N, Huttenhower C. bioBakery: a meta'omic analysis environment. Bioinformatics. 2018 Apr 1;34(7):1235-1237. PMID: 29194469.

## Rights

* Copyright (c) 2021 Respiratory Immunology lab, Monash University, Melbourne, Australia.
* License: This pipeline is provided under the MIT license (See LICENSE.txt for details)
* Authors: C. Pattaroni
