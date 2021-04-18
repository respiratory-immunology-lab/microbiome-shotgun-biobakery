#!/bin/bash
#SBATCH --job-name=HUMAnN
#SBATCH --account=of33
#SBATCH --time=3-00:00:00
#SBATCH --ntasks=36
#SBATCH --mem=200G

# Load necessary environment and modules
source activate biobakery3
module load gnuparallel

# Run MetaPhlAn and HUMAnN
mkdir humann_output
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
